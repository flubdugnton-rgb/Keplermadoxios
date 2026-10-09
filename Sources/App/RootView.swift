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
    @State private var homeResetID = UUID()
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
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
        Group {
            switch selection {
            case .home:
                HomeView(resetID: homeResetID, onOpenSubjects: { selection = .subjects })
            case .subjects:
                LibraryView()
            case .pomodoro:
                PomodoroView()
            case .questions:
                QuestionsView()
            case .notes:
                NotesView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNavigation(
                selection: $selection,
                showProfile: $showProfile,
                intensity: intensity,
                onReselect: { destination in
                    if destination == .home {
                        homeResetID = UUID()
                    }
                }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $showProfile) {
            ProfileSettingsView()
                .preferredColorScheme(preferredScheme)
                .presentationDragIndicator(.visible)
        }
    }
}

private struct BottomNavigation: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @Binding var selection: MainDestination
    @Binding var showProfile: Bool
    let intensity: Double
    let onReselect: (MainDestination) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(MainDestination.allCases) { destination in
                Button {
                    if selection == destination {
                        onReselect(destination)
                    } else {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                            selection = destination
                        }
                    }
                } label: {
                    ZStack {
                        if selection == destination {
                            Capsule(style: .continuous)
                                .fill(Color.accentColor.opacity(0.10 + 0.05 * intensity))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(0.16 + 0.16 * intensity), lineWidth: 0.7)
                                }
                                .padding(.horizontal, 2)
                                .padding(.vertical, 2)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }

                        VStack(spacing: 2) {
                            Image(systemName: selection == destination ? destination.selectedIcon : destination.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(destination.title)
                                .font(.system(size: 9.2, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(selection == destination ? Color.accentColor : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                showProfile = true
            } label: {
                AvatarView(photoURL: auth.photoURL)
                    .frame(width: 38, height: 38)
                    .padding(.horizontal, 5)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Abrir perfil e configurações")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(height: 62)
        .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10 + 0.20 * intensity), lineWidth: 0.8)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
        .fixedSize(horizontal: false, vertical: true)
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
