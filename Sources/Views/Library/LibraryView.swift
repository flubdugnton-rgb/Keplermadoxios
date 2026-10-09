import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 75

    private let initialType: StudyContentType?

    init(initialType: StudyContentType? = nil) {
        self.initialType = initialType
    }

    private var intensity: Double { Double(glassIntensityPercent) / 100.0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let initialType {
                            ContentTypeHeader(type: initialType, intensity: intensity)
                        }

                        ForEach(catalog.subjects) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject, preferredType: initialType)
                            } label: {
                                SubjectRow(subject: subject)
                                    .padding(18)
                                    .kepleraeGlass(intensity: intensity, cornerRadius: 24)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(initialType?.title ?? "Biblioteca")
        }
    }
}

private struct ContentTypeHeader: View {
    let type: StudyContentType
    let intensity: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: type.icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text(type.title).font(.headline)
                Text(type.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .kepleraeGlass(intensity: intensity, cornerRadius: 24, interactive: false)
    }
}
