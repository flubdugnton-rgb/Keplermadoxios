import SwiftUI

enum MainDestination: String, CaseIterable, Identifiable, Hashable {
    case home, subjects, pomodoro, questions, notes, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Início"
        case .subjects: return "Biblioteca"
        case .pomodoro: return "Pomodoro"
        case .questions: return "Questões"
        case .notes: return "Notas"
        case .profile: return "Perfil"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .subjects: return "square.grid.2x2"
        case .pomodoro: return "timer"
        case .questions: return "questionmark.square"
        case .notes: return "note.text"
        case .profile: return "person.crop.circle"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @State private var selection: MainDestination = .home
    @State private var lastContentSelection: MainDestination = .home
    @State private var showProfile = false
    @State private var homeResetID = UUID()
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue

    private var theme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }
    private var preferredScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        ZStack {
            if auth.isSignedIn {
                mainShell
                    .transition(.opacity.combined(with: .scale(scale: 1.01)))
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 0.99)))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: auth.isSignedIn)
        .preferredColorScheme(preferredScheme)
    }

    private var mainShell: some View {
        TabView(selection: $selection) {
            Tab("Início", systemImage: "house", value: MainDestination.home) {
                HomeView(resetID: homeResetID, onOpenSubjects: { selection = .subjects })
            }

            Tab("Biblioteca", systemImage: "square.grid.2x2", value: MainDestination.subjects) {
                LibraryView()
            }

            Tab("Pomodoro", systemImage: "timer", value: MainDestination.pomodoro) {
                PomodoroView()
            }

            Tab("Questões", systemImage: "questionmark.square", value: MainDestination.questions) {
                QuestionsView()
            }

            Tab("Notas", systemImage: "note.text", value: MainDestination.notes) {
                NotesView()
            }

            Tab(value: MainDestination.profile) {
                Color.clear
                    .ignoresSafeArea()
            } label: {
                AvatarView(photoURL: auth.photoURL)
                    .frame(width: 30, height: 30)
                    .accessibilityLabel("Perfil")
            }
        }
        .tint(.accentColor)
        .onChange(of: selection) { oldValue, newValue in
            if newValue == .profile {
                showProfile = true
                return
            }

            lastContentSelection = newValue

            if newValue == .home && oldValue != .home {
                homeResetID = UUID()
            }
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            if selection == .profile {
                selection = lastContentSelection
            }
        }) {
            ProfileSettingsView()
                .preferredColorScheme(preferredScheme)
                .presentationDragIndicator(.visible)
        }
    }
}

struct AvatarView: View {
    let photoURL: String

    var body: some View {
        ZStack {
            Circle().fill(.thinMaterial)
            if let url = URL(string: photoURL), !photoURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}
