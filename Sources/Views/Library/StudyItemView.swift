import SwiftUI

struct StudyItemView: View {
    let item: StudyItem

    var body: some View {
        Group {
            if let fileID = item.driveFileID,
               let url = GoogleDriveURLBuilder.previewURL(fileID: fileID) {
                DrivePlayerView(url: url)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView(
                    "Conteúdo indisponível",
                    systemImage: item.type.icon,
                    description: Text("Este item ainda não recebeu o ID do arquivo do Google Drive.")
                )
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
