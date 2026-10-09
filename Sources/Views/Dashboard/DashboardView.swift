import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 75

    private var intensity: Double { Double(glassIntensityPercent) / 100.0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        StatCard(
                            title: "Matérias",
                            value: "\(catalog.subjects.count)",
                            icon: "books.vertical.fill",
                            intensity: intensity
                        )

                        StatCard(
                            title: "Conteúdos importados",
                            value: "\(catalog.items.count)",
                            icon: "square.stack.3d.up.fill",
                            intensity: intensity
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Próxima etapa", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                            Text("Trazer o catálogo, links e regras da versão Android para preencher o app iOS sem alterar a organização do conteúdo.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Progresso")
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let intensity: Double

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(title)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
    }
}
