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
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

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
        ZStack(alignment: .bottom) {
            AmbientBackground(style: selection == .pomodoro ? .focus : .standard)
                .ignoresSafeArea()

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
            .background(Color.clear)
            .animation(.snappy(duration: 0.32, extraBounce: 0.04), value: selection)

            KepleraeTabBar(
                selection: $selection,
                showProfile: $showProfile,
                homeResetID: $homeResetID,
                intensity: intensity
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .zIndex(20)
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
        HStack(spacing: 2) {
            ForEach(MainDestination.allCases) { destination in
                Button {
                    if destination == .home && selection == .home {
                        homeResetID = UUID()
                    }

                    withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
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
                        .frame(width: 31, height: 31)
                    Text("Perfil")
                        .font(.system(size: 9.5, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Perfil e ajustes")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(height: 64)
        .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.42 * intensity),
                            .white.opacity(0.08),
                            .white.opacity(0.28 * intensity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.09), radius: 14, y: 6)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tabLabel(_ destination: MainDestination) -> some View {
        ZStack {
            if selection == destination {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.10 + 0.08 * intensity))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(.white.opacity(0.18 + 0.18 * intensity), lineWidth: 0.8)
                    }
                    .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
            }

            VStack(spacing: 2) {
                Image(systemName: selection == destination ? destination.selectedIcon : destination.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))

                Text(destination.title)
                    .font(.system(size: 9.4, weight: .medium))
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
                    case .success(let image):
                        image.resizable().scaledToFill()
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
        .overlay(Circle().stroke(.white.opacity(0.68), lineWidth: 1.1))
        .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
    }
}
