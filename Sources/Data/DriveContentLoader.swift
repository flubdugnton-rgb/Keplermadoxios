import Foundation

@MainActor
final class DriveContentLoader: ObservableObject {
    enum State {
        case idle
        case loading
        case ready(URL)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    func load(item: StudyItem, auth: GoogleAuthStore) async {
        if case .ready = state { return }
        state = .loading

        do {
            guard item.linkKind == .file, !item.driveFileID.isEmpty else {
                throw DriveContentError.missingFileID
            }

            let token = try await auth.freshDriveAccessToken()
            let localURL = try await Self.download(item: item, accessToken: token)
            guard !Task.isCancelled else { return }
            state = .ready(localURL)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }

    nonisolated private static func download(item: StudyItem, accessToken: String) async throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("KepleraeDrive", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let ext = preferredExtension(for: item)
        let destination = directory.appendingPathComponent("\(item.driveFileID).\(ext)")

        if fileManager.fileExists(atPath: destination.path),
           let values = try? destination.resourceValues(forKeys: [.fileSizeKey]),
           (values.fileSize ?? 0) > 0 {
            return destination
        }

        guard let encodedID = item.driveFileID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(encodedID)?alt=media&supportsAllDrives=true") else {
            throw DriveContentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 180
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 60 * 60
        let session = URLSession(configuration: configuration)

        let (temporaryURL, response) = try await session.download(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw DriveContentError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw DriveContentError.httpStatus(http.statusCode)
        }

        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    nonisolated private static func preferredExtension(for item: StudyItem) -> String {
        let existing = (item.filename as NSString).pathExtension
        if !existing.isEmpty { return existing }

        switch item.type {
        case .lesson: return "mp4"
        case .pdf: return "pdf"
        case .audio: return "m4a"
        }
    }
}

enum DriveContentError: LocalizedError {
    case missingFileID
    case invalidURL
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingFileID:
            return "Este material não possui um ID de arquivo válido no Google Drive."
        case .invalidURL:
            return "Não foi possível montar o endereço deste material."
        case .invalidResponse:
            return "O Google Drive retornou uma resposta inválida."
        case .httpStatus(let code):
            if code == 401 {
                return "A sessão do Google expirou. Tente abrir o material novamente."
            }
            if code == 403 {
                return "Sua conta não tem permissão para ler este arquivo do Google Drive."
            }
            if code == 404 {
                return "O arquivo não foi encontrado no Google Drive."
            }
            return "Não foi possível baixar o material do Google Drive (erro \(code))."
        }
    }
}
