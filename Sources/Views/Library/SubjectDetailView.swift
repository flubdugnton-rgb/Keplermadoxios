import SwiftUI

struct SubjectDetailView: View {
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let subject: Subject
    let preferredType: StudyContentType?
    init(subject: Subject, preferredType: StudyContentType? = nil) { self.subject = subject; self.preferredType = preferredType }
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(preferredType.map { [$0] } ?? StudyContentType.allCases) { type in
                        NavigationLink { FolderBrowserView(subject: subject, type: type, path: []) } label: {
                            HStack(spacing: 16) {
                                Image(systemName: type.icon).font(.title2).frame(width: 34)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(type.title).font(.title3.bold())
                                    Text(type.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(20).kepleraeGlass(intensity: intensity, cornerRadius: 26)
                        }.buttonStyle(.plain)
                    }
                }.padding(20)
            }
        }
        .navigationTitle(subject.title).navigationBarTitleDisplayMode(.inline)
    }
}

struct FolderBrowserView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let subject: Subject
    let type: StudyContentType
    let path: [String]
    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var folders: [String] { catalog.childFolders(for: subject, type: type, path: path) }
    private var items: [StudyItem] { catalog.directItems(for: subject, type: type, path: path) }

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(folders, id: \.self) { folder in
                        NavigationLink { FolderBrowserView(subject: subject, type: type, path: path + [folder]) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "folder.fill").foregroundStyle(.secondary)
                                Text(folder).font(.body.weight(.semibold)).multilineTextAlignment(.leading)
                                Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
                            }.padding(17).kepleraeGlass(intensity: intensity, cornerRadius: 22)
                        }.buttonStyle(.plain)
                    }
                    ForEach(items) { item in
                        NavigationLink { StudyItemView(item: item) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: type.icon).frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                                    if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                                }
                                Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
                            }.padding(17).kepleraeGlass(intensity: intensity, cornerRadius: 22)
                        }.buttonStyle(.plain)
                    }
                    if folders.isEmpty && items.isEmpty {
                        ContentUnavailableView("Sem conteúdo", systemImage: type.icon, description: Text("Não há itens nesta pasta."))
                            .padding(.top, 70)
                    }
                }.padding(20)
            }
        }
        .navigationTitle(path.last ?? type.title).navigationBarTitleDisplayMode(.inline)
    }
}
