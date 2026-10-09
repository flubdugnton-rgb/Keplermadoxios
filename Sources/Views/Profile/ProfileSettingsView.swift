import SwiftUI
import UniformTypeIdentifiers

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: GoogleAuthStore
    @EnvironmentObject private var notes: NotesStore
    @EnvironmentObject private var questions: QuestionsStore
    @EnvironmentObject private var pomodoro: PomodoroStore
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @State private var exportDocument: BackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var message: String?

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
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        profileHeader
                        appearanceSection
                        googleSection
                        dataSection

                        Button(role: .destructive) {
                            auth.signOut()
                            dismiss()
                        } label: {
                            Label("Desconectar", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                        .tint(.red)

                        Text("Kepleræ 1.3 · SwiftUI · iOS 27")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .buttonStyle(.glass)
                }
            }
        }
        .preferredColorScheme(preferredScheme)
        .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "Keplerae-backup-1.3") { result in
            if case .failure(let error) = result {
                message = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            importBackup(result)
        }
        .alert("Transferência de dados", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            AvatarView(photoURL: auth.photoURL)
                .frame(width: 94, height: 94)
            Text(auth.displayName.isEmpty ? "Minha conta" : auth.displayName)
                .font(.title2.bold())
            Text(auth.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Seu espaço, do seu jeito.")
                .font(.headline)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .kepleraeGlass(intensity: intensity, cornerRadius: 32, interactive: false)
    }

    private var appearanceSection: some View {
        SettingsSection(title: "Aparência", icon: "circle.lefthalf.filled", intensity: intensity) {
            HStack(spacing: 12) {
                ThemeChoice(
                    title: "Claro",
                    kind: .sun,
                    tint: .orange,
                    selected: appThemeRaw == AppTheme.light.rawValue
                ) {
                    appThemeRaw = AppTheme.light.rawValue
                }

                ThemeChoice(
                    title: "Escuro",
                    kind: .moon,
                    tint: .green,
                    selected: appThemeRaw == AppTheme.dark.rawValue
                ) {
                    appThemeRaw = AppTheme.dark.rawValue
                }
            }

            Button {
                appThemeRaw = AppTheme.system.rawValue
            } label: {
                Label("Acompanhar o sistema", systemImage: "macbook.and.iphone")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .tint(appThemeRaw == AppTheme.system.rawValue ? .cyan : .secondary)

            Divider()

            HStack {
                Text("Liquid Glass").font(.headline)
                Spacer()
                Text("\(glassIntensityPercent)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(glassIntensityPercent) },
                    set: { glassIntensityPercent = Int($0.rounded()) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(.cyan)

            HStack {
                Text("Mais sutil")
                Spacer()
                Text("Mais intenso")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var googleSection: some View {
        SettingsSection(title: "Google", icon: "person.crop.circle.badge.checkmark", intensity: intensity) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.blue.opacity(0.10)).frame(width: 42, height: 42)
                    Text("G").font(.title3.bold()).foregroundStyle(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Conta conectada").font(.headline)
                    Text(auth.email).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            }

            Text("A mesma conta é usada para identidade e recursos do Google Drive do Kepleræ.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "Seus dados", icon: "arrow.up.arrow.down.circle", intensity: intensity) {
            Button { prepareExport() } label: {
                Label("Exportar dados e configurações", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Button { importing = true } label: {
                Label("Importar dados e configurações", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func prepareExport() {
        let backup = KepleraeBackup(
            schemaVersion: 1,
            appVersion: "1.3",
            exportedAt: .now,
            notes: notes.notes,
            noteTags: notes.tags,
            questionSubjects: questions.subjects,
            questionRecords: questions.records,
            pomodoroSettings: pomodoro.settings,
            pomodoroHistory: pomodoro.history,
            theme: AppTheme(rawValue: appThemeRaw) ?? .system,
            glassIntensity: glassIntensityPercent,
            googleEmail: auth.email
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(backup) {
            exportDocument = BackupDocument(data: data)
            exporting = true
        }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(KepleraeBackup.self, from: data)

            notes.replace(tags: backup.noteTags, notes: backup.notes)
            questions.replace(subjects: backup.questionSubjects, records: backup.questionRecords)
            pomodoro.replace(settings: backup.pomodoroSettings, history: backup.pomodoroHistory)
            appThemeRaw = backup.theme.rawValue
            glassIntensityPercent = backup.glassIntensity
            message = "Dados importados com sucesso."
        } catch {
            message = "Não foi possível importar: \(error.localizedDescription)"
        }
    }
}

private enum ThemeArtKind {
    case sun, moon
}

private struct ThemeChoice: View {
    let title: String
    let kind: ThemeArtKind
    let tint: Color
    let selected: Bool
    let action: () -> Void
    @State private var trigger = 0

    var body: some View {
        Button {
            trigger += 1
            action()
        } label: {
            VStack(spacing: 10) {
                Group {
                    switch kind {
                    case .sun:
                        AnimatedSun(trigger: trigger, selected: selected)
                    case .moon:
                        AnimatedMoon(trigger: trigger, selected: selected)
                    }
                }
                .frame(width: 64, height: 64)

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 116)
        }
        .buttonStyle(.plain)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(selected ? tint.opacity(0.82) : Color.secondary.opacity(0.16), lineWidth: selected ? 2 : 1)
        )
    }
}

private struct AnimatedSun: View {
    let trigger: Int
    let selected: Bool
    @State private var rotation = 0.0
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color.orange)
                    .frame(width: 5, height: 14)
                    .offset(y: -27)
                    .rotationEffect(.degrees(Double(index) * 45 + rotation))
            }

            Circle()
                .fill(Color.orange)
                .frame(width: 34, height: 34)
                .shadow(color: .orange.opacity(selected ? 0.35 : 0.12), radius: selected ? 9 : 3)
                .scaleEffect(pulse ? 1.06 : 0.96)
        }
        .onChange(of: trigger) { _, _ in
            withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                rotation += 28
                pulse.toggle()
            }
        }
    }
}

private struct AnimatedMoon: View {
    let trigger: Int
    let selected: Bool
    @State private var sparkleScale = 0.8
    @State private var sparkleRotation = 0.0

    var body: some View {
        ZStack {
            Image(systemName: "moon.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.green)
                .shadow(color: .green.opacity(selected ? 0.28 : 0.10), radius: selected ? 8 : 3)

            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.mint)
                .offset(x: 19, y: -18)
                .scaleEffect(sparkleScale)
                .rotationEffect(.degrees(sparkleRotation))
        }
        .onChange(of: trigger) { _, _ in
            withAnimation(.spring(response: 0.42, dampingFraction: 0.58)) {
                sparkleScale = sparkleScale > 1 ? 0.8 : 1.35
                sparkleRotation += 45
            }
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let intensity: Double
    let content: Content

    init(title: String, icon: String, intensity: Double, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.intensity = intensity
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon).font(.title3.bold())
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
    }
}
