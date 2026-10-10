import SwiftUI
import UIKit

@main
struct KepleraeApp: App {
    init() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.backgroundColor = .clear
        navigationAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().isTranslucent = true
    }

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
