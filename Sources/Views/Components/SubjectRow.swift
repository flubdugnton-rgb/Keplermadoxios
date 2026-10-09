import SwiftUI

struct SubjectRow: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: subject.icon)
                .frame(width: 28)
            Text(subject.title)
                .font(.body.weight(.medium))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}
