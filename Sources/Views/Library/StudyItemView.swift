import SwiftUI

struct StudyItemView: View {
    let item: StudyItem
    var body: some View {
        Group {
            if let url = item.previewURL { DrivePlayerView(url: url).ignoresSafeArea(edges: .bottom) }
            else { ContentUnavailableView("Conteúdo indisponível", systemImage: item.type.icon, description: Text("O link deste conteúdo não é válido.")) }
        }
        .navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
    }
}
