import SwiftUI

enum MainDestination: String, CaseIterable, Identifiable {
    case home, subjects, pomodoro, questions, notes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Início"
        case .subjects: return "Matérias"
        case .pomodoro: return "Pomodoro"
        case .questions: return "Questões"
        case .notes: return "Notas"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .subjects: return "books.vertical"
        case .pomodoro: return "timer"
        case .questions: return "checkmark.circle"
        case .notes: return "note.text"
        }
    }
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .subjects: return "books.vertical.fill"
        case .pomodoro: return "timer"
        case .questions: return "checkmark.circle.fill"
        case .notes: return "note.text"
        }
    }
}

struct RootView: View {
    @State private var selection: MainDestination = .home
    @State private var showProfile = false
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var theme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }

    var body: some View {
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
        .preferredColorScheme(theme == .system ? nil : (theme == .dark ? .dark : .light))
    }
}

private struct BottomNavigation: View {
    @Binding var selection: MainDestination
    @Binding var showProfile: Bool
    let intensity: Double
    @AppStorage("googlePhotoURL") private var googlePhotoURL = ""

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(MainDestination.allCases) { destination in
                    Button {
                        withAnimation(.snappy(duration: 0.22)) { selection = destination }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: selection == destination ? destination.selectedIcon : destination.icon)
                                .font(.system(size: 19, weight: .semibold))
                            Text(destination.title)
                                .font(.system(size: 9.5, weight: .medium))
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
                    AvatarView(photoURL: googlePhotoURL)
                        .frame(width: 36, height: 36)
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
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Image(systemName: "person.fill") }
            } else {
                Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
    }
}
