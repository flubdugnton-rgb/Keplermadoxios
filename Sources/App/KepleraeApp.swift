import SwiftUI

@main
struct KepleraeApp: App {
    @StateObject private var auth = GoogleAuthStore()
    @StateObject private var catalog = CatalogStore()
    @StateObject private var notes = NotesStore()
    @StateObject private var questions = QuestionsStore()
    @StateObject private var pomodoro = PomodoroStore()
    @StateObject private var studyState = StudyStateStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(catalog)
                .environmentObject(notes)
                .environmentObject(questions)
                .environmentObject(pomodoro)
                .environmentObject(studyState)
                .onOpenURL { url in _ = auth.handle(url) }
        }
    }
}
