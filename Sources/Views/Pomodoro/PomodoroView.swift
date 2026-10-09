import SwiftUI

enum PomodoroTab: String, CaseIterable, Identifiable {
    case focus = "Foco", progress = "Progresso", settings = "Ajustes"
    var id: String { rawValue }
}

struct PomodoroView: View {
    @EnvironmentObject private var store: PomodoroStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @AppStorage("pomodoroAmbientEnabled") private var ambientEnabled = false
    @AppStorage("pomodoroAmbientVolume") private var ambientVolume = 0.35
    @AppStorage("pomodoroAmbientSound") private var ambientSoundRaw = AmbientSound.rain.rawValue

    @StateObject private var soundPlayer = AmbientSoundPlayer()
    @State private var tab: PomodoroTab = .focus
    @State private var floatingArt = false
    @State private var twinkle = false

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var ambientSound: AmbientSound { AmbientSound(rawValue: ambientSoundRaw) ?? .rain }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(style: .focus)
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pomodoro").font(.largeTitle.bold())
                            Text("Uma estrela de cada vez.").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("Pomodoro", selection: $tab) {
                            ForEach(PomodoroTab.allCases) { value in Text(value.rawValue).tag(value) }
                        }
                        .pickerStyle(.segmented)

                        switch tab {
                        case .focus: focusView
                        case .progress: progressView
                        case .settings: settingsView
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            floatingArt = true
            twinkle = true
            syncAmbient()
        }
        .onDisappear { soundPlayer.stop() }
        .onChange(of: store.running) { _, _ in syncAmbient() }
        .onChange(of: store.phase) { _, _ in syncAmbient() }
        .onChange(of: ambientEnabled) { _, _ in syncAmbient() }
        .onChange(of: ambientSoundRaw) { _, _ in syncAmbient() }
        .onChange(of: ambientVolume) { _, value in soundPlayer.updateVolume(value) }
    }

    private var focusView: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<7, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "star.fill" : "sparkles")
                        .font(.system(size: CGFloat(8 + (index % 3) * 4)))
                        .foregroundStyle(index.isMultiple(of: 2) ? .yellow : .purple)
                        .opacity(twinkle ? 0.22 + Double(index % 3) * 0.18 : 0.8)
                        .offset(x: CGFloat([-125,-92,-55,68,102,128,18][index]), y: CGFloat([-56,40,-90,-80,42,-28,74][index]))
                        .animation(.easeInOut(duration: 1.4 + Double(index) * 0.17).repeatForever(autoreverses: true), value: twinkle)
                }

                ZStack {
                    Image("PomodoroRest")
                        .resizable().scaledToFit()
                        .opacity(store.running && store.phase == .focus ? 0 : 1)
                    Image("PomodoroFishing")
                        .resizable().scaledToFit()
                        .opacity(store.running && store.phase == .focus ? 1 : 0)
                }
                .frame(height: 260)
                .offset(y: floatingArt ? -6 : 7)
                .scaleEffect(floatingArt ? 1.01 : 0.985)
                .animation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true), value: floatingArt)
                .animation(.easeInOut(duration: 0.55), value: store.running)
            }
            .frame(height: 278)

            Text(store.phase.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.purple)

            Text(timeString(store.remainingSeconds))
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            VStack(spacing: 6) {
                Text(store.running ? "Em andamento" : "Pronto para começar")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(min(store.cycle, store.settings.cycles)) de \(store.settings.cycles) focos concluídos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.purple)
                .padding(.horizontal, 4)

            HStack(spacing: 22) {
                roundControl("arrow.counterclockwise", size: 52) { store.reset() }
                roundControl(store.running ? "pause.fill" : "play.fill", size: 72, prominent: true) {
                    store.running ? store.pause() : store.start()
                }
                roundControl("forward.end.fill", size: 52) { store.skip() }
            }

            Text("Só focos completos entram no total. Pular ou zerar não registra um pomodoro.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
        }
        .padding(20)
        .background(Color.purple.opacity(0.035), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .kepleraeGlass(intensity: intensity, cornerRadius: 32, interactive: false)
    }

    private var progressView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                MetricCard(value: "\(store.history.count)", title: "Pomodoros", tint: .purple, intensity: intensity)
                MetricCard(value: "\(totalFocusMinutes)min", title: "Tempo de foco", tint: .mint, intensity: intensity)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Últimos 7 dias").font(.title2.bold())
                Text("Minutos de foco concluídos").font(.subheadline).foregroundStyle(.secondary)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(lastSevenDays, id: \.0) { day, minutes in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(colors: [.purple.opacity(0.75), .cyan.opacity(0.55)], startPoint: .bottom, endPoint: .top))
                                .frame(height: max(5, CGFloat(minutes) * 2.2))
                            Text(day).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 150, alignment: .bottom)
            }
            .padding(20)
            .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)

            VStack(alignment: .leading, spacing: 10) {
                Text("Seu histórico").font(.title2.bold())
                if store.history.isEmpty {
                    Text("Seu primeiro foco concluído aparecerá aqui.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                } else {
                    ForEach(store.history.sorted(by: { $0.finishedAt > $1.finishedAt }).prefix(10)) { record in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text("\(record.durationSeconds / 60) min de foco").font(.subheadline.weight(.semibold))
                                Text(record.finishedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var settingsView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 15) {
                Label("Crie seu ambiente", systemImage: "leaf.fill").font(.title2.bold()).foregroundStyle(.purple)
                Text("Escolha um som e encontre seu ritmo.").foregroundStyle(.secondary)

                Toggle("Som durante o foco", isOn: $ambientEnabled)
                    .font(.headline)
                HStack {
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(.purple)
                    Slider(value: $ambientVolume, in: 0...1)
                    Text("\(Int(ambientVolume * 100))%").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary).frame(width: 46)
                }
            }
            .padding(20)
            .background(LinearGradient(colors: [.purple.opacity(0.12), .cyan.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AmbientSound.allCases.filter { $0 != .none }) { sound in
                    Button {
                        ambientSoundRaw = sound.rawValue
                        ambientEnabled = true
                    } label: {
                        AmbientSoundCard(sound: sound, selected: ambientSound == sound, intensity: intensity)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Duração dos ciclos").font(.title3.bold())
                Stepper("Foco: \(store.settings.focusMinutes) min", value: intSetting(\.focusMinutes), in: 1...180)
                Stepper("Pausa curta: \(store.settings.shortMinutes) min", value: intSetting(\.shortMinutes), in: 1...90)
                Stepper("Pausa longa: \(store.settings.longMinutes) min", value: intSetting(\.longMinutes), in: 1...90)
                Stepper("Ciclos: \(store.settings.cycles)", value: intSetting(\.cycles), in: 1...12)
                Toggle("Avançar automaticamente", isOn: boolSetting(\.autoAdvance))
                Toggle("Sons de aviso", isOn: boolSetting(\.sounds))
            }
            .padding(20)
            .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
        }
    }

    private var progress: Double {
        let total = max(1, store.settings.minutes(for: store.phase) * 60)
        return 1 - Double(store.remainingSeconds) / Double(total)
    }

    private var totalFocusMinutes: Int { store.history.reduce(0) { $0 + $1.durationSeconds / 60 } }

    private var lastSevenDays: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter(); formatter.dateFormat = "dd/MM"
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
            let minutes = store.history.filter { calendar.isDate($0.finishedAt, inSameDayAs: date) }.reduce(0) { $0 + $1.durationSeconds / 60 }
            return (formatter.string(from: date), minutes)
        }
    }

    private func timeString(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }

    private func roundControl(_ icon: String, size: CGFloat, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: prominent ? 25 : 18, weight: .semibold)).frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? Color.white : Color.purple)
        .background(prominent ? Color.purple : Color.white.opacity(0.45), in: Circle())
        .kepleraeGlass(intensity: prominent ? 0.15 : intensity, cornerRadius: size / 2, interactive: true)
    }

    private func intSetting(_ keyPath: WritableKeyPath<PomodoroSettings, Int>) -> Binding<Int> {
        Binding(get: { store.settings[keyPath: keyPath] }, set: { value in var draft = store.settings; draft[keyPath: keyPath] = value; store.configure(draft) })
    }

    private func boolSetting(_ keyPath: WritableKeyPath<PomodoroSettings, Bool>) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: keyPath] }, set: { value in var draft = store.settings; draft[keyPath: keyPath] = value; store.configure(draft) })
    }

    private func syncAmbient() {
        if ambientEnabled && store.running && ambientSound != .none {
            soundPlayer.play(ambientSound, volume: ambientVolume)
        } else {
            soundPlayer.stop()
        }
    }
}

private struct MetricCard: View {
    let value: String
    let title: String
    let tint: Color
    let intensity: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value).font(.title.bold()).monospacedDigit()
            Text(title).font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(18)
        .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .kepleraeGlass(intensity: intensity, cornerRadius: 26, interactive: false)
    }
}

private struct AmbientSoundCard: View {
    let sound: AmbientSound
    let selected: Bool
    let intensity: Double

    var tint: Color {
        switch sound {
        case .clock: return .purple
        case .wind: return .blue
        case .rain: return .mint
        case .storm: return .pink
        case .fire: return .orange
        case .library: return .indigo
        case .room: return .cyan
        case .none: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sound.icon).font(.title3).foregroundStyle(tint)
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple) }
            }
            Spacer(minLength: 8)
            Text(sound.title).font(.headline)
            Text(sound.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(selected ? Color.purple.opacity(0.8) : .clear, lineWidth: 2))
        .kepleraeGlass(intensity: intensity, cornerRadius: 26)
    }
}
