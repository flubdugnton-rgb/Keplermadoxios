import Foundation

@MainActor
final class DriveContentLoader: ObservableObject {
    enum PreparedContent: Equatable {
        case local(URL)
        case stream(URL)
    }

    enum State: Equatable {
        case idle
        case loading
        case ready(PreparedContent)
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
            guard !Task.isCancelled else { return }

            switch item.type {
            case .lesson, .audio:
                let url = try Self.streamingURL(fileID: item.driveFileID, accessToken: token)
                state = .ready(.stream(url))

            case .pdf:
                let localURL = try await Self.downloadPDF(item: item, accessToken: token)
                guard !Task.isCancelled else { return }
                state = .ready(.local(localURL))
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }

    nonisolated private static func streamingURL(fileID: String, accessToken: String) throws -> URL {
        guard var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files/\(fileID)") else {
            throw DriveContentError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "alt", value: "media"),
            URLQueryItem(name: "supportsAllDrives", value: "true"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        guard let url = components.url else { throw DriveContentError.invalidURL }
        return url
    }

    nonisolated private static func downloadPDF(item: StudyItem, accessToken: String) async throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("KepleraeDrive", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent("\(item.driveFileID).pdf")
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
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadRevalidatingCacheData

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 24 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 60 * 30
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
            if code == 401 { return "A sessão do Google expirou. Abra o material novamente." }
            if code == 403 { return "Sua conta não tem permissão para ler este arquivo do Google Drive." }
            if code == 404 { return "O arquivo não foi encontrado no Google Drive." }
            return "Não foi possível carregar o material do Google Drive (erro \(code))."
        }
    }
}
