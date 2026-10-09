import SwiftUI

struct StudyItemView: View {
    @EnvironmentObject private var studyState: StudyStateStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let item: StudyItem
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        ZStack {
            AmbientBackground(style: .library)
            VStack(spacing: 12) {
                if let url = item.previewURL {
                    DrivePlayerView(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .kepleraeGlass(intensity: intensity, cornerRadius: 24, interactive: false)
                } else {
                    ContentUnavailableView("Conteúdo indisponível", systemImage: item.type.icon, description: Text("O link deste conteúdo não é válido."))
                }

                HStack(spacing: 10) {
                    Button { studyState.toggleFavorite(item.id) } label: {
                        Label(studyState.isFavorite(item.id) ? "Favoritado" : "Favoritar", systemImage: studyState.isFavorite(item.id) ? "star.fill" : "star")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)

                    Button { studyState.toggleCompleted(item.id) } label: {
                        Label(studyState.isCompleted(item.id) ? "Concluído" : "Concluir", systemImage: studyState.isCompleted(item.id) ? "checkmark.circle.fill" : "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { studyState.markOpened(item.id) }
    }
}
