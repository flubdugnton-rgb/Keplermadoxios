import SwiftUI

enum StudyStatusFilter: String, CaseIterable, Identifiable {
    case all, favorites, pending, completed
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return "Todos"
        case .favorites: return "Favoritos"
        case .pending: return "Pendentes"
        case .completed: return "Concluídos"
        }
    }
}

struct SubjectDetailView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var studyState: StudyStateStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let subject: Subject
    let preferredType: StudyContentType?

    @State private var query = ""
    @State private var status: StudyStatusFilter = .all
    @State private var type: StudyContentType?

    init(subject: Subject, preferredType: StudyContentType? = nil) {
        self.subject = subject
        self.preferredType = preferredType
        _type = State(initialValue: preferredType)
    }

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var palette: SubjectPalette { .forSubject(subject.id) }

    private var filteredItems: [StudyItem] {
        catalog.items(for: subject, type: type).filter { item in
            let statusMatches: Bool = {
                switch status {
                case .all: return true
                case .favorites: return studyState.isFavorite(item.id)
                case .pending: return !studyState.isCompleted(item.id)
                case .completed: return studyState.isCompleted(item.id)
                }
            }()
            let queryMatches = query.isEmpty || item.title.localizedCaseInsensitiveContains(query) || item.folderPath.joined(separator: " ").localizedCaseInsensitiveContains(query)
            return statusMatches && queryMatches
        }
    }

    private var rootFolders: [String] {
        let names = filteredItems.compactMap(\.folderPath.first)
        return Array(Set(names)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var rootItems: [StudyItem] { filteredItems.filter { $0.folderPath.isEmpty } }

    var body: some View {
        ZStack {
            AmbientBackground(style: .library)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    subjectHero
                    searchField
                    statusFilters
                    typeFilters

                    if !query.isEmpty {
                        Text("Resultados").font(.title3.bold()).padding(.top, 3)
                        ForEach(filteredItems) { item in itemLink(item) }
                    } else {
                        ForEach(rootFolders, id: \.self) { folder in
                            NavigationLink {
                                FolderBrowserView(subject: subject, type: type, status: status, path: [folder])
                            } label: {
                                FolderRow(title: folder, count: filteredItems.filter { $0.folderPath.first == folder }.count, palette: palette, intensity: intensity)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(rootItems) { item in itemLink(item) }
                    }

                    if filteredItems.isEmpty {
                        ContentUnavailableView("Nenhum material", systemImage: "magnifyingglass", description: Text("Tente alterar os filtros ou a busca."))
                            .padding(.top, 38)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(subject.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subjectHero: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack {
                Circle().fill(.white.opacity(0.30)).frame(width: 60, height: 60)
                Image(systemName: subject.icon).font(.title.bold())
            }
            Text(subject.title).font(.largeTitle.bold())
            Text(subject.subtitle).font(.headline).foregroundStyle(.secondary)
            Text("\(catalog.count(for: subject)) materiais").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(colors: [palette.primary.opacity(0.34), palette.secondary.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Buscar aulas, arquivos e pastas", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain) }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .kepleraeGlass(intensity: intensity, cornerRadius: 26, interactive: true)
    }

    private var statusFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(StudyStatusFilter.allCases) { value in
                    FilterPill(title: value.title, selected: status == value) { withAnimation(.snappy) { status = value } }
                }
            }
        }.scrollIndicators(.hidden)
    }

    private var typeFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterPill(title: "Todos os formatos", selected: type == nil) { type = nil }
                ForEach(StudyContentType.allCases) { value in
                    FilterPill(title: value.title, selected: type == value) { type = value }
                }
            }
        }.scrollIndicators(.hidden)
    }

    private func itemLink(_ item: StudyItem) -> some View {
        NavigationLink { StudyItemView(item: item) } label: {
            StudyItemRow(item: item, intensity: intensity)
        }.buttonStyle(.plain)
    }
}

struct FolderBrowserView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var studyState: StudyStateStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let subject: Subject
    let type: StudyContentType?
    let status: StudyStatusFilter
    let path: [String]

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var palette: SubjectPalette { .forSubject(subject.id) }

    private var scoped: [StudyItem] {
        catalog.items(for: subject, type: type, path: path).filter { item in
            switch status {
            case .all: return true
            case .favorites: return studyState.isFavorite(item.id)
            case .pending: return !studyState.isCompleted(item.id)
            case .completed: return studyState.isCompleted(item.id)
            }
        }
    }

    private var folders: [String] {
        let values = scoped.compactMap { $0.folderPath.count > path.count ? $0.folderPath[path.count] : nil }
        return Array(Set(values)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var items: [StudyItem] { scoped.filter { $0.folderPath.count == path.count } }

    var body: some View {
        ZStack {
            AmbientBackground(style: .library)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(folders, id: \.self) { folder in
                        NavigationLink {
                            FolderBrowserView(subject: subject, type: type, status: status, path: path + [folder])
                        } label: {
                            FolderRow(title: folder, count: scoped.filter { $0.folderPath.dropFirst(path.count).first == folder }.count, palette: palette, intensity: intensity)
                        }.buttonStyle(.plain)
                    }
                    ForEach(items) { item in
                        NavigationLink { StudyItemView(item: item) } label: { StudyItemRow(item: item, intensity: intensity) }.buttonStyle(.plain)
                    }
                    if folders.isEmpty && items.isEmpty {
                        ContentUnavailableView("Sem conteúdo", systemImage: "folder", description: Text("Não há itens com estes filtros."))
                            .padding(.top, 70)
                    }
                }.padding(20)
            }
        }
        .navigationTitle(path.last ?? subject.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FolderRow: View {
    let title: String
    let count: Int
    let palette: SubjectPalette
    let intensity: Double
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.white.opacity(0.26)).frame(width: 44, height: 44)
                Image(systemName: "folder.fill").foregroundStyle(palette.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                Text("\(count) materiais").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(15)
        .background(palette.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .kepleraeGlass(intensity: intensity, cornerRadius: 22)
    }
}

private struct StudyItemRow: View {
    @EnvironmentObject private var studyState: StudyStateStore
    let item: StudyItem
    let intensity: Double
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: item.type.icon)
                .frame(width: 28)
                .foregroundStyle(item.type.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 6)
            if studyState.isFavorite(item.id) { Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption) }
            if studyState.isCompleted(item.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption) }
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(15)
        .background(item.type.tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .kepleraeGlass(intensity: intensity, cornerRadius: 22)
    }
}

private struct FilterPill: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if selected { Image(systemName: "checkmark").font(.caption.bold()) }
                Text(title).font(.subheadline.weight(selected ? .semibold : .regular))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(selected ? Color.cyan.opacity(0.23) : Color.primary.opacity(0.035), in: Capsule())
        .overlay(Capsule().stroke(selected ? Color.cyan.opacity(0.50) : Color.secondary.opacity(0.20), lineWidth: 1))
    }
}
