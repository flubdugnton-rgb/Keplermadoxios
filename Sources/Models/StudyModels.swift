import Foundation

struct Subject: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let icon: String
}

enum StudyContentType: String, CaseIterable, Identifiable, Codable {
    case lesson
    case pdf
    case audio

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

struct StudyItem: Identifiable, Hashable, Codable {
    let id: String
    let subjectID: String
    let type: StudyContentType
    let title: String
    let subtitle: String?
    let driveFileID: String?
}
