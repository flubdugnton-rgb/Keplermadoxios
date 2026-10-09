import SwiftUI
import UniformTypeIdentifiers

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notes: NotesStore
    @EnvironmentObject private var questions: QuestionsStore
    @EnvironmentObject private var pomodoro: PomodoroStore
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @AppStorage("googleEmail") private var googleEmail = ""
    @AppStorage("googlePhotoURL") private var googlePhotoURL = ""
    @State private var exportDocument: BackupDocument?
    @State private var exporting = false; @State private var importing = false; @State private var message: String?
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 10) {
                            AvatarView(photoURL: googlePhotoURL).frame(width: 88, height: 88)
                            Text(googleEmail.isEmpty ? "Minha conta" : googleEmail).font(.title2.bold())
                            Text("Configurações do Kepleræ").foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity).padding(22).kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)

                        SettingsSection(title: "Aparência", icon: "circle.lefthalf.filled", intensity: intensity) {
                            Picker("Tema", selection: $appThemeRaw) { ForEach(AppTheme.allCases) { Text($0.title).tag($0.rawValue) } }.pickerStyle(.segmented)
                            Divider()
                            Text("Liquid Glass · \(glassIntensityPercent)%").font(.headline)
                            Picker("Intensidade", selection: $glassIntensityPercent) { ForEach(Array(stride(from: 0, through: 100, by: 10)), id: \.self) { Text("\($0)%").tag($0) } }
                                .pickerStyle(.wheel).frame(height: 120).clipped()
                        }

                        SettingsSection(title: "Google", icon: "cloud.fill", intensity: intensity) {
                            TextField("E-mail da conta Google", text: $googleEmail).textInputAutocapitalization(.never).keyboardType(.emailAddress).textFieldStyle(.roundedBorder)
                            TextField("URL da foto (opcional)", text: $googlePhotoURL).textInputAutocapitalization(.never).keyboardType(.URL).textFieldStyle(.roundedBorder)
                            Text("O catálogo usa os links do Google Drive da versão Android. O login OAuth nativo do iOS será conectado quando o Client ID iOS for adicionado ao projeto.")
                                .font(.caption).foregroundStyle(.secondary)
                        }

                        SettingsSection(title: "Seus dados", icon: "arrow.up.arrow.down.circle", intensity: intensity) {
                            Button { prepareExport() } label: { Label("Exportar dados e configurações", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity, alignment: .leading) }
                            Divider()
                            Button { importing = true } label: { Label("Importar dados e configurações", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, alignment: .leading) }
                        }

                        Text("Kepleræ 1.1 · Madox Fênix").font(.caption).foregroundStyle(.secondary).padding(.top, 2)
                    }.padding(20)
                }
            }
            .navigationTitle("Perfil").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } } }
        }
        .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "Keplerae-backup-1.1") { result in if case .failure(let error) = result { message = error.localizedDescription } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in importBackup(result) }
        .alert("Transferência de dados", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK") { message = nil } } message: { Text(message ?? "") }
    }

    private func prepareExport() {
        let backup = KepleraeBackup(schemaVersion: 1, appVersion: "1.1", exportedAt: .now,
            notes: notes.notes, noteTags: notes.tags, questionSubjects: questions.subjects, questionRecords: questions.records,
            pomodoroSettings: pomodoro.settings, pomodoroHistory: pomodoro.history,
            theme: AppTheme(rawValue: appThemeRaw) ?? .system, glassIntensity: glassIntensityPercent, googleEmail: googleEmail)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(backup) { exportDocument = BackupDocument(data: data); exporting = true }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url); let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(KepleraeBackup.self, from: data)
            notes.replace(tags: backup.noteTags, notes: backup.notes); questions.replace(subjects: backup.questionSubjects, records: backup.questionRecords)
            pomodoro.replace(settings: backup.pomodoroSettings, history: backup.pomodoroHistory)
            appThemeRaw = backup.theme.rawValue; glassIntensityPercent = backup.glassIntensity; googleEmail = backup.googleEmail
            message = "Dados importados com sucesso."
        } catch { message = "Não foi possível importar: \(error.localizedDescription)" }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String; let icon: String; let intensity: Double; let content: Content
    init(title: String, icon: String, intensity: Double, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.intensity = intensity; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon).font(.title3.bold())
            content
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
    }
}
