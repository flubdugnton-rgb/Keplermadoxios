import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    private let initialType: StudyContentType?
    init(initialType: StudyContentType? = nil) { self.initialType = initialType }
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(catalog.subjects) { subject in
                            NavigationLink { SubjectDetailView(subject: subject, preferredType: initialType) } label: {
                                SubjectRow(subject: subject, count: catalog.items(for: subject, type: initialType).count)
                                    .padding(18)
                                    .kepleraeGlass(intensity: intensity, cornerRadius: 24)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 16)
                }
            }
            .navigationTitle(initialType?.title ?? "Matérias")
        }
    }
}
