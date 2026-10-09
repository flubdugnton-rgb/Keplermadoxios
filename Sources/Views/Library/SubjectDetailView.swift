import SwiftUI

struct SubjectDetailView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 75

    let subject: Subject
    let preferredType: StudyContentType?

    init(subject: Subject, preferredType: StudyContentType? = nil) {
        self.subject = subject
        self.preferredType = preferredType
    }

    private var intensity: Double { Double(glassIntensityPercent) / 100.0 }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(typesToShow) { type in
                        let content = catalog.items(for: subject, type: type)

                        VStack(alignment: .leading, spacing: 12) {
                            Label(type.title, systemImage: type.icon)
                                .font(.title3.bold())

                            if content.isEmpty {
                                EmptyImportedContentRow(type: type)
                            } else {
                                ForEach(content) { item in
                                    NavigationLink {
                                        StudyItemView(item: item)
                                    } label: {
                                        StudyItemRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(18)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 26, interactive: false)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(subject.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var typesToShow: [StudyContentType] {
        if let preferredType { return [preferredType] }
        return StudyContentType.allCases
    }
}

private struct EmptyImportedContentRow: View {
    let type: StudyContentType

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Aguardando importação")
                    .font(.subheadline.weight(.semibold))
                Text("Os \(type.title.lowercased()) desta matéria serão trazidos da versão Android.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct StudyItemRow: View {
    let item: StudyItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
