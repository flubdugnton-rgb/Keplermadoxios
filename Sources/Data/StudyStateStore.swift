import Foundation

@MainActor
final class StudyStateStore: ObservableObject {
    @Published private(set) var favorites: Set<String> = []
    @Published private(set) var completed: Set<String> = []
    @Published private(set) var lastOpenedID: String?

    private let key = "keplerae.studyState.v1"

    private struct Payload: Codable {
        var favorites: Set<String>
        var completed: Set<String>
        var lastOpenedID: String?
    }

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        favorites = payload.favorites
        completed = payload.completed
        lastOpenedID = payload.lastOpenedID
    }

    func isFavorite(_ id: String) -> Bool { favorites.contains(id) }
    func isCompleted(_ id: String) -> Bool { completed.contains(id) }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
        save()
    }

    func toggleCompleted(_ id: String) {
        if completed.contains(id) { completed.remove(id) } else { completed.insert(id) }
        save()
    }

    func markOpened(_ id: String) {
        lastOpenedID = id
        save()
    }

    private func save() {
        let payload = Payload(favorites: favorites, completed: completed, lastOpenedID: lastOpenedID)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
