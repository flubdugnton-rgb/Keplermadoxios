import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let onOpenSubjects: () -> Void
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kepleræ").font(.system(size: 39, weight: .bold, design: .rounded))
                            Text("Seu espaço de estudos").font(.headline).foregroundStyle(.secondary)
                        }

                        GlassEffectContainer(spacing: 14) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(StudyContentType.allCases) { type in
                                    NavigationLink { LibraryView(initialType: type) } label: { StudyCard(type: type, intensity: intensity) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Matérias", systemImage: "books.vertical.fill").font(.title3.bold())
                                Spacer()
                                Button("Ver todas", action: onOpenSubjects).font(.subheadline.weight(.semibold))
                            }
                            ForEach(catalog.subjects) { subject in
                                NavigationLink { SubjectDetailView(subject: subject) } label: {
                                    SubjectRow(subject: subject, count: catalog.count(for: subject))
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)

                        if let error = catalog.loadError {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.footnote).foregroundStyle(.secondary).padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 26).padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
