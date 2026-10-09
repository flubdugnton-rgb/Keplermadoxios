import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    private let initialType: StudyContentType?
    private let embedded: Bool
    init(initialType: StudyContentType? = nil, embedded: Bool = false) {
        self.initialType = initialType
        self.embedded = embedded
    }
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        Group {
            if embedded {
                libraryContent
            } else {
                NavigationStack { libraryContent }
            }
        }
    }

    private var libraryContent: some View {
        ZStack {
            AmbientBackground(style: .library)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(initialType?.title ?? "Biblioteca")
                            .font(.largeTitle.bold())
                        Text("Aulas, PDFs e áudios do seu catálogo.")
                            .foregroundStyle(.secondary)
                        Text("\(catalog.items.count) materiais · \(catalog.count(for: .lesson)) aulas · \(catalog.count(for: .pdf)) PDFs · \(catalog.count(for: .audio)) áudios")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if let error = catalog.loadError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    ForEach(catalog.subjects) { subject in
                        NavigationLink {
                            SubjectDetailView(subject: subject, preferredType: initialType)
                        } label: {
                            LibrarySubjectCard(subject: subject, count: catalog.items(for: subject, type: initialType).count, intensity: intensity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 118)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(initialType?.title ?? "Biblioteca")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LibrarySubjectCard: View {
    let subject: Subject
    let count: Int
    let intensity: Double

    var body: some View {
        let palette = SubjectPalette.forSubject(subject.id)
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(.white.opacity(0.30)).frame(width: 54, height: 54)
                Image(systemName: subject.icon).font(.title2.bold())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title).font(.headline)
                Text(subject.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text("\(count) materiais").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            LinearGradient(colors: [palette.primary.opacity(0.24), palette.secondary.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .kepleraeGlass(intensity: intensity, cornerRadius: 26)
    }
}
