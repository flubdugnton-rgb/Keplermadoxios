import Foundation

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var tags: [NoteTag] = []
    @Published private(set) var notes: [StudyNote] = []
    private let key = "keplerae.notes.v1"

    init() { load() }

    func createTag(_ raw: String) throws -> UUID {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !name.isEmpty, name.count <= 30 else { throw StoreError.message("Use um nome de 1 a 30 caracteres.") }
        if let existing = tags.first(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) { return existing.id }
        let tag = NoteTag(id: UUID(), name: name)
        tags.append(tag); save(); return tag.id
    }

    func renameTag(_ id: UUID, to raw: String) throws {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 30 else { throw StoreError.message("Use um nome de 1 a 30 caracteres.") }
        guard !tags.contains(where: { $0.id != id && $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) else {
            throw StoreError.message("Esse bloco já existe.")
        }
        if let i = tags.firstIndex(where: { $0.id == id }) { tags[i].name = name; save() }
    }

    func deleteTag(_ id: UUID) {
        tags.removeAll { $0.id == id }
        for i in notes.indices where notes[i].tagID == id { notes[i].tagID = nil }
        save()
    }

    func upsert(_ note: StudyNote) {
        if let i = notes.firstIndex(where: { $0.id == note.id }) { notes[i] = note }
        else { notes.append(note) }
        save()
    }

    func delete(_ id: UUID) { notes.removeAll { $0.id == id }; save() }

    func visible(tagID: UUID?, query: String) -> [StudyNote] {
        let needle = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return notes.filter { note in
            let tagMatches = tagID == nil || note.tagID == tagID
            let haystack = "\(note.title) \(note.body)".folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            return tagMatches && (needle.isEmpty || haystack.contains(needle))
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func replace(tags: [NoteTag], notes: [StudyNote]) { self.tags = tags; self.notes = notes; save() }

    private struct Payload: Codable { let tags: [NoteTag]; let notes: [StudyNote] }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        tags = payload.tags; notes = payload.notes
    }
    private func save() {
        if let data = try? JSONEncoder().encode(Payload(tags: tags, notes: notes)) { UserDefaults.standard.set(data, forKey: key) }
    }
}

enum StoreError: LocalizedError { case message(String); var errorDescription: String? { if case .message(let m) = self { return m }; return nil } }
