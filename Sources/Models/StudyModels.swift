import Foundation

struct Subject: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let monogram: String
}

enum StudyContentType: String, CaseIterable, Identifiable, Codable {
    case lesson = "VIDEO"
    case pdf = "PDF"
    case audio = "AUDIO"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lesson: return "Aulas"
        case .pdf: return "PDFs"
        case .audio: return "Áudios"
        }
    }

    var subtitle: String {
        switch self {
        case .lesson: return "Vídeos e conteúdos"
        case .pdf: return "Materiais de estudo"
        case .audio: return "Conteúdo em áudio"
        }
    }

    var icon: String {
        switch self {
        case .lesson: return "play.rectangle.fill"
        case .pdf: return "doc.text.fill"
        case .audio: return "headphones"
        }
    }
}

enum LinkKind: String, Codable { case file = "FILE", folder = "FOLDER" }

struct StudyItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let filename: String
    let subjectID: String
    let folderPath: [String]
    let type: StudyContentType
    let url: String
    let linkKind: LinkKind
    let driveFileID: String
    let note: String
    let source: String

    enum CodingKeys: String, CodingKey {
        case id, title, filename, folderPath, type, url, linkKind, note, source
        case subjectID = "subjectId"
        case driveFileID = "driveFileId"
    }

    var previewURL: URL? {
        if linkKind == .file, !driveFileID.isEmpty {
            return URL(string: "https://drive.google.com/file/d/\(driveFileID)/preview")
        }
        return URL(string: url)
    }
}

struct NoteTag: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}

struct StudyNote: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var body: String
    var tagID: UUID?
    var tone: Int
    let createdAt: Date
    var updatedAt: Date
}

struct QuestionSubject: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}

struct QuestionRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let subjectID: UUID
    let correct: Int
    let wrong: Int
    let recordedAt: Date

    var total: Int { correct + wrong }
    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) * 100 }
}

enum PomodoroPhase: String, Codable, CaseIterable {
    case focus, shortBreak, longBreak

    var title: String {
        switch self {
        case .focus: return "Foco"
        case .shortBreak: return "Pausa curta"
        case .longBreak: return "Pausa longa"
        }
    }
}

struct PomodoroSettings: Hashable, Codable {
    var focusMinutes = 25
    var shortMinutes = 5
    var longMinutes = 15
    var cycles = 4
    var autoAdvance = false
    var sounds = true

    func minutes(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus: return focusMinutes
        case .shortBreak: return shortMinutes
        case .longBreak: return longMinutes
        }
    }
}

struct FocusRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let finishedAt: Date
    let durationSeconds: Int
}

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }
}
