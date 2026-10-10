import Foundation

struct DriveStreamDescriptor: Equatable {
    let url: URL
    let accessToken: String
    let mimeType: String
}

@MainActor
final class DriveContentLoader: ObservableObject {
    enum PreparedContent: Equatable {
        case local(URL)
        case stream(DriveStreamDescriptor)
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
            case .lesson:
                state = .ready(.stream(try Self.streamDescriptor(
                    fileID: item.driveFileID,
                    accessToken: token,
                    mimeType: "video/mp4"
                )))

            case .audio:
                state = .ready(.stream(try Self.streamDescriptor(
                    fileID: item.driveFileID,
                    accessToken: token,
                    mimeType: "audio/mpeg"
                )))

            case .pdf:
                let localURL = try await Self.download(item: item, accessToken: token)
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

    nonisolated static func streamDescriptor(
        fileID: String,
        accessToken: String,
        mimeType: String
    ) throws -> DriveStreamDescriptor {
        guard let encodedID = fileID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(encodedID)?alt=media&supportsAllDrives=true") else {
            throw DriveContentError.invalidURL
        }

        return DriveStreamDescriptor(
            url: url,
            accessToken: accessToken,
            mimeType: mimeType
        )
    }

    /// Full-file fallback used only if AVPlayer cannot begin the authenticated range stream.
    /// The result is cached so a material that has already fallen back opens immediately next time.
    nonisolated static func download(item: StudyItem, accessToken: String) async throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
        request.cachePolicy = .reloadRevalidatingCacheData

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 24 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024
        )
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
        case .audio: return "mp3"
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
            if code == 401 { return "A sessão do Google expirou. Abra o material novamente." }
            if code == 403 { return "Sua conta não tem permissão para ler este arquivo do Google Drive." }
            if code == 404 { return "O arquivo não foi encontrado no Google Drive." }
            return "Não foi possível carregar o material do Google Drive (erro \(code))."
        }
    }
}
