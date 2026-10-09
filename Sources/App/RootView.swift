import SwiftUI

enum MainDestination: Int, CaseIterable, Identifiable, Hashable {
    case home = 0
    case pomodoro
    case questions
    case notes

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Início"
        case .pomodoro: return "Pomodoro"
        case .questions: return "Questões"
        case .notes: return "Notas"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .pomodoro: return "timer"
        case .questions: return "questionmark.square"
        case .notes: return "note.text"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
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

    private var theme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }
    private var preferredScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        ZStack {
            if auth.isSignedIn {
                mainShell
                    .transition(.opacity.combined(with: .scale(scale: 1.005)))
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.24), value: auth.isSignedIn)
        .preferredColorScheme(preferredScheme)
    }

    private var mainShell: some View {
        TabView(selection: $selection) {
            HomeView(resetID: homeResetID)
                .tag(MainDestination.home)

            PomodoroView()
                .tag(MainDestination.pomodoro)

            QuestionsView()
                .tag(MainDestination.questions)

            NotesView()
                .tag(MainDestination.notes)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.snappy(duration: 0.34, extraBounce: 0.05), value: selection)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            KepleraeTabBar(
                selection: $selection,
                showProfile: $showProfile,
                homeResetID: $homeResetID,
                intensity: intensity
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 5)
        }
        .sheet(isPresented: $showProfile) {
            ProfileSettingsView()
                .preferredColorScheme(preferredScheme)
                .presentationDragIndicator(.visible)
        }
    }
}

private struct KepleraeTabBar: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @Binding var selection: MainDestination
    @Binding var showProfile: Bool
    @Binding var homeResetID: UUID
    let intensity: Double
    @Namespace private var selectionNamespace

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(MainDestination.allCases) { destination in
                    Button {
                        if destination == .home && selection == .home {
                            homeResetID = UUID()
                        }
                        withAnimation(.snappy(duration: 0.32, extraBounce: 0.08)) {
                            selection = destination
                        }
                    } label: {
                        tabLabel(destination)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(destination.title)
                }

                Button {
                    showProfile = true
                } label: {
                    VStack(spacing: 2) {
                        AvatarView(photoURL: auth.photoURL)
                            .frame(width: 29, height: 29)
                        Text("Perfil")
                            .font(.system(size: 9.5, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Perfil e ajustes")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(height: 64)
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.10 + 0.16 * intensity), lineWidth: 0.7)
                    .allowsHitTesting(false)
            }
        }
    }

    private func tabLabel(_ destination: MainDestination) -> some View {
        ZStack {
            if selection == destination {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.14 + 0.08 * intensity))
                    .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
            }

            VStack(spacing: 2) {
                Image(systemName: selection == destination ? destination.selectedIcon : destination.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(destination.title)
                    .font(.system(size: 9.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(selection == destination ? Color.accentColor : .primary)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .contentShape(Rectangle())
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
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.62), lineWidth: 1))
    }
}
