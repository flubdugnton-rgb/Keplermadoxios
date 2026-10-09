import SwiftUI

struct StudyCard: View {
    let type: StudyContentType
    let intensity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: type.icon)
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.headline)
                Text(type.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(18)
        .kepleraeGlass(intensity: intensity, cornerRadius: 28)
    }
}
