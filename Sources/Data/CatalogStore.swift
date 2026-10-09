import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var subjects: [Subject] = [
        Subject(id: "fisioterapia", title: "Fisioterapia", subtitle: "HU Brasil · módulos e simulados", icon: "figure.walk", monogram: "F"),
        Subject(id: "portugues", title: "Português", subtitle: "Gramática e interpretação", icon: "text.book.closed.fill", monogram: "P"),
        Subject(id: "matematica", title: "Matemática e Raciocínio Lógico", subtitle: "Lógica, teoria e questões", icon: "function", monogram: "M"),
        Subject(id: "hu_legislacao", title: "HU Legislação", subtitle: "Normas e legislação EBSERH", icon: "building.columns.fill", monogram: "H"),
        Subject(id: "sus", title: "SUS", subtitle: "Saúde pública e políticas", icon: "cross.case.fill", monogram: "S"),
        Subject(id: "profisio", title: "Profisio", subtitle: "Artigos, aulas e áudios por ciclo", icon: "figure.strengthtraining.traditional", monogram: "Pr")
    ]

    @Published private(set) var items: [StudyItem] = []
    @Published private(set) var loadError: String?

    init() { loadBundledCatalog() }

    func items(for subject: Subject, type: StudyContentType? = nil, path: [String] = []) -> [StudyItem] {
        items.filter { item in
            item.subjectID == subject.id &&
            (type == nil || item.type == type) &&
            item.folderPath.prefix(path.count).elementsEqual(path)
        }
    }

    func directItems(for subject: Subject, type: StudyContentType? = nil, path: [String]) -> [StudyItem] {
        items(for: subject, type: type, path: path).filter { $0.folderPath.count == path.count }
    }

    func childFolders(for subject: Subject, type: StudyContentType? = nil, path: [String]) -> [String] {
        let names = items(for: subject, type: type, path: path).compactMap { item -> String? in
            guard item.folderPath.count > path.count else { return nil }
            return item.folderPath[path.count]
        }
        return Array(Set(names)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func count(for subject: Subject) -> Int { items.filter { $0.subjectID == subject.id }.count }

    private func loadBundledCatalog() {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            loadError = "O catálogo do Android não foi incluído no aplicativo."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            items = try JSONDecoder().decode([StudyItem].self, from: data)
            loadError = nil
        } catch {
            loadError = "Não foi possível carregar o catálogo: \(error.localizedDescription)"
        }
    }
}
