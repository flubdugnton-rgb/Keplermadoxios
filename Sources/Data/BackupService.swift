import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct KepleraeBackup: Codable {
    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let notes: [StudyNote]
    let noteTags: [NoteTag]
    let questionSubjects: [QuestionSubject]
    let questionRecords: [QuestionRecord]
    let pomodoroSettings: PomodoroSettings
    let pomodoroHistory: [FocusRecord]
    let theme: AppTheme
    let glassIntensity: Int
    let googleEmail: String
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: data) }
}
