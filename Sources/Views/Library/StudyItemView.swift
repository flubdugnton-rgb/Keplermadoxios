import SwiftUI

struct StudyItemView: View {
    @EnvironmentObject private var studyState: StudyStateStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85

    let item: StudyItem

    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AmbientBackground(style: .library)

                ScrollView {
                    VStack(spacing: 12) {
                        player(proxy: proxy)

                        actionButtons
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, 96)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { studyState.markOpened(item.id) }
    }

    @ViewBuilder
    private func player(proxy: GeometryProxy) -> some View {
        if item.linkKind == .file, !item.driveFileID.isEmpty {
            DrivePlayerView(item: item)
                .frame(height: playerHeight(width: proxy.size.width - 28, viewportHeight: proxy.size.height))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .kepleraeGlass(intensity: intensity, cornerRadius: 24, interactive: false)
        } else {
            ContentUnavailableView(
                "Conteúdo indisponível",
                systemImage: item.type.icon,
                description: Text("O link deste conteúdo não é válido.")
            )
            .frame(height: 300)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                studyState.toggleFavorite(item.id)
            } label: {
                Label(
                    studyState.isFavorite(item.id) ? "Favoritado" : "Favoritar",
                    systemImage: studyState.isFavorite(item.id) ? "star.fill" : "star"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)

            Button {
                studyState.toggleCompleted(item.id)
            } label: {
                Label(
                    studyState.isCompleted(item.id) ? "Concluído" : "Concluir",
                    systemImage: studyState.isCompleted(item.id) ? "checkmark.circle.fill" : "checkmark.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .controlSize(.large)
        .padding(.top, 2)
    }

    private func playerHeight(width: CGFloat, viewportHeight: CGFloat) -> CGFloat {
        switch item.type {
        case .lesson:
            // Course videos are overwhelmingly landscape. Keeping the player near 16:9
            // prevents the Favorite/Complete controls from falling behind the floating tab bar.
            return min(max(width * 9.0 / 16.0, 210), 270)

        case .pdf:
            // PDF keeps a useful reading area, while the full-screen control handles long reading.
            return min(max(viewportHeight * 0.58, 420), 520)

        case .audio:
            return min(max(viewportHeight * 0.42, 310), 380)
        }
    }
}
