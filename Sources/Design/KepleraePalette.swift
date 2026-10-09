import SwiftUI

struct SubjectPalette {
    let primary: Color
    let secondary: Color

    static func forSubject(_ id: String) -> SubjectPalette {
        switch id {
        case "fisioterapia": return .init(primary: .mint, secondary: .teal)
        case "portugues": return .init(primary: .pink, secondary: .purple)
        case "matematica": return .init(primary: .blue, secondary: .indigo)
        case "hu_legislacao": return .init(primary: .orange, secondary: .yellow)
        case "sus": return .init(primary: .green, secondary: .mint)
        case "profisio": return .init(primary: .purple, secondary: .indigo)
        default: return .init(primary: .blue, secondary: .cyan)
        }
    }
}

extension StudyContentType {
    var tint: Color {
        switch self {
        case .lesson: return .blue
        case .pdf: return .purple
        case .audio: return .pink
        }
    }
}
