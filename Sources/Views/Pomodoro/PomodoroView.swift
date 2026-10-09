import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject private var store: PomodoroStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @State private var showSettings = false
    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Pomodoro").font(.largeTitle.bold())
                                Text("Estude em ciclos e preserve o ritmo.").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3").font(.title3) }
                                .buttonStyle(.bordered)
                        }

                        VStack(spacing: 18) {
                            Text(store.phase.title).font(.title3.weight(.semibold)).foregroundStyle(.secondary)
                            Text(timeString(store.remainingSeconds)).font(.system(size: 64, weight: .semibold, design: .rounded)).monospacedDigit()
                            ProgressView(value: progress).tint(.accentColor)
                            Text("Ciclo \(min(store.cycle + 1, store.settings.cycles)) de \(store.settings.cycles)").font(.subheadline).foregroundStyle(.secondary)

                            HStack(spacing: 14) {
                                Button { store.running ? store.pause() : store.start() } label: {
                                    Label(store.running ? "Pausar" : "Iniciar", systemImage: store.running ? "pause.fill" : "play.fill")
                                        .frame(maxWidth: .infinity)
                                }.buttonStyle(.borderedProminent).controlSize(.large)
                                Button { store.reset() } label: { Image(systemName: "arrow.counterclockwise") }.buttonStyle(.bordered).controlSize(.large)
                                Button { store.skip() } label: { Image(systemName: "forward.end.fill") }.buttonStyle(.bordered).controlSize(.large)
                            }
                        }
                        .padding(24).kepleraeGlass(intensity: intensity, cornerRadius: 32, interactive: false)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Histórico de foco", systemImage: "chart.bar.xaxis").font(.title3.bold())
                            if store.history.isEmpty {
                                Text("Conclua seu primeiro ciclo de foco para começar o histórico.").foregroundStyle(.secondary)
                            } else {
                                ForEach(store.history.sorted(by: { $0.finishedAt > $1.finishedAt }).prefix(8)) { record in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        VStack(alignment: .leading) {
                                            Text("\(record.durationSeconds / 60) min de foco").font(.subheadline.weight(.semibold))
                                            Text(record.finishedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }.padding(.vertical, 4)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
                    }.padding(20)
                }
            }.toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSettings) { PomodoroSettingsView() }
    }

    private var progress: Double {
        let total = max(1, store.settings.minutes(for: store.phase) * 60)
        return 1 - Double(store.remainingSeconds) / Double(total)
    }
    private func timeString(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
}

private struct PomodoroSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PomodoroStore
    @State private var draft = PomodoroSettings()

    var body: some View {
        NavigationStack {
            Form {
                Section("Duração") {
                    Stepper("Foco: \(draft.focusMinutes) min", value: $draft.focusMinutes, in: 1...180)
                    Stepper("Pausa curta: \(draft.shortMinutes) min", value: $draft.shortMinutes, in: 1...90)
                    Stepper("Pausa longa: \(draft.longMinutes) min", value: $draft.longMinutes, in: 1...90)
                    Stepper("Ciclos: \(draft.cycles)", value: $draft.cycles, in: 1...12)
                }
                Section("Comportamento") {
                    Toggle("Avançar automaticamente", isOn: $draft.autoAdvance)
                    Toggle("Sons", isOn: $draft.sounds)
                }
            }
            .navigationTitle("Pomodoro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salvar") { store.configure(draft); dismiss() } }
            }
            .onAppear { draft = store.settings }
        }
    }
}
