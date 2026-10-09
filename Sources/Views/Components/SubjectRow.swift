import SwiftUI

struct SubjectRow: View {
    let subject: Subject
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: subject.icon).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.title).font(.body.weight(.medium))
                if let count { Text("\(count) conteúdos").font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}
