import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 75

    private var intensity: Double { Double(glassIntensityPercent) / 100.0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kepleræ")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                            Text("Seu espaço de estudos")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)

                        GlassEffectContainer(spacing: 18) {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 16
                            ) {
                                ForEach(StudyContentType.allCases) { type in
                                    NavigationLink {
                                        LibraryView(initialType: type)
                                    } label: {
                                        StudyCard(type: type, intensity: intensity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Matérias", systemImage: "books.vertical.fill")
                                .font(.title3.bold())

                            ForEach(catalog.subjects) { subject in
                                NavigationLink {
                                    SubjectDetailView(subject: subject)
                                } label: {
                                    SubjectRow(subject: subject)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
