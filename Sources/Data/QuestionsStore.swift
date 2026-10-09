import Foundation

@MainActor
final class QuestionsStore: ObservableObject {
    @Published private(set) var subjects: [QuestionSubject] = []
    @Published private(set) var records: [QuestionRecord] = []
    private let key = "keplerae.questions.v1"

    init() { load() }

    func createSubject(_ raw: String) throws -> UUID {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 80 else { throw StoreError.message("Use um nome de 1 a 80 caracteres.") }
        guard !subjects.contains(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) else {
            throw StoreError.message("Essa matéria já existe.")
        }
        let subject = QuestionSubject(id: UUID(), name: name)
        subjects.append(subject); save(); return subject.id
    }

    func add(subjectID: UUID, correct: Int, wrong: Int) throws {
        guard subjects.contains(where: { $0.id == subjectID }) else { throw StoreError.message("Escolha uma matéria.") }
        guard correct >= 0, wrong >= 0, correct <= 1_000_000, wrong <= 1_000_000, correct + wrong > 0 else {
            throw StoreError.message("Use inteiros de 0 a 1.000.000. O total deve ser maior que zero.")
        }
        records.append(QuestionRecord(id: UUID(), subjectID: subjectID, correct: correct, wrong: wrong, recordedAt: .now)); save()
    }

    func deleteRecord(_ id: UUID) { records.removeAll { $0.id == id }; save() }
    func deleteSubject(_ id: UUID) { subjects.removeAll { $0.id == id }; records.removeAll { $0.subjectID == id }; save() }
    func reset() { subjects = []; records = []; save() }

    func totals(subjectID: UUID? = nil) -> (correct: Int, wrong: Int, total: Int, accuracy: Double) {
        let filtered = records.filter { subjectID == nil || $0.subjectID == subjectID }
        let c = filtered.reduce(0) { $0 + $1.correct }, w = filtered.reduce(0) { $0 + $1.wrong }, t = c + w
        return (c, w, t, t == 0 ? 0 : Double(c) / Double(t) * 100)
    }

    func replace(subjects: [QuestionSubject], records: [QuestionRecord]) { self.subjects = subjects; self.records = records; save() }

    private struct Payload: Codable { let subjects: [QuestionSubject]; let records: [QuestionRecord] }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        subjects = payload.subjects; records = payload.records
    }
    private func save() {
        if let data = try? JSONEncoder().encode(Payload(subjects: subjects, records: records)) { UserDefaults.standard.set(data, forKey: key) }
    }
}
