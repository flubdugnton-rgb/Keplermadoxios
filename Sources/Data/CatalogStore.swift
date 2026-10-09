import Foundation

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var subjects: [Subject] = [
        Subject(id: "fisioterapia", title: "Fisioterapia", icon: "figure.walk"),
        Subject(id: "portugues", title: "Português", icon: "text.book.closed.fill"),
        Subject(id: "matematica", title: "Matemática e Raciocínio Lógico", icon: "function"),
        Subject(id: "hu-legislacao", title: "HU — Legislação", icon: "building.columns.fill"),
        Subject(id: "sus", title: "SUS", icon: "cross.case.fill")
    ]

    @Published private(set) var items: [StudyItem] = []

    func items(for subject: Subject, type: StudyContentType? = nil) -> [StudyItem] {
        items.filter { item in
            item.subjectID == subject.id && (type == nil || item.type == type)
        }
    }

    func replaceCatalog(subjects: [Subject], items: [StudyItem]) {
        self.subjects = subjects
        self.items = items
    }
}
