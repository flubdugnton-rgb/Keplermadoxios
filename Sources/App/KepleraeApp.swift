import SwiftUI

@main
struct KepleraeApp: App {
    @StateObject private var catalog = CatalogStore()
    @StateObject private var notes = NotesStore()
    @StateObject private var questions = QuestionsStore()
    @StateObject private var pomodoro = PomodoroStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(catalog)
                .environmentObject(notes)
                .environmentObject(questions)
                .environmentObject(pomodoro)
        }
    }
}
