import Foundation

enum GoogleDriveURLBuilder {
    static func previewURL(fileID: String) -> URL? {
        guard !fileID.isEmpty else { return nil }
        return URL(string: "https://drive.google.com/file/d/\(fileID)/preview")
    }
}
