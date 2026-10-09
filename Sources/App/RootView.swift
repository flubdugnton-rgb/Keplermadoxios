import SwiftUI

enum MainDestination: String, CaseIterable, Identifiable {
    case home, subjects, pomodoro, questions, notes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Início"
        case .subjects: return "Biblioteca"
        case .pomodoro: return "Pomodoro"
        case .questions: return "Questões"
        case .notes: return "Notas"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .subjects: return "square.grid.2x2"
        case .pomodoro: return "timer"
        case .questions: return "questionmark.square"
        case .notes: return "note.text"
        }
    }
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .subjects: return "square.grid.2x2.fill"
        case .pomodoro: return "timer"
        case .questions: return "questionmark.square.fill"
        case .notes: return "note.text"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @State private var selection: MainDestination = .home
    @State private var showProfile = false
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var theme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }

    var body: some View {
        ZStack {
            if auth.isSignedIn {
                mainShell
                    .transition(.opacity.combined(with: .scale(scale: 1.015)))
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isSignedIn)
        .preferredColorScheme(theme == .system ? nil : (theme == .dark ? .dark : .light))
    }

    private var mainShell: some View {
        Group {
            switch selection {
            case .home: HomeView(onOpenSubjects: { selection = .subjects })
            case .subjects: LibraryView()
            case .pomodoro: PomodoroView()
            case .questions: QuestionsView()
            case .notes: NotesView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNavigation(selection: $selection, showProfile: $showProfile, intensity: intensity)
                .padding(.horizontal, 10)
                .padding(.bottom, 3)
        }
        .sheet(isPresented: $showProfile) { ProfileSettingsView() }
    }
}

private struct BottomNavigation: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @Binding var selection: MainDestination
    @Binding var showProfile: Bool
    let intensity: Double

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(MainDestination.allCases) { destination in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { selection = destination }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: selection == destination ? destination.selectedIcon : destination.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .symbolEffect(.bounce, value: selection == destination)
                            Text(destination.title)
                                .font(.system(size: 9.2, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(selection == destination ? Color.accentColor : .primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Button { showProfile = true } label: {
                    AvatarView(photoURL: auth.photoURL)
                        .frame(width: 37, height: 37)
                        .padding(.horizontal, 5)
                        .accessibilityLabel("Abrir perfil e configurações")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: true)
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
                    case .success(let image): image.resizable().scaledToFill()
                    default: Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
                    }
                }
            } else {
                Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}
