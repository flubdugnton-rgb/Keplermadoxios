import SwiftUI

enum PomodoroTab: String, CaseIterable, Identifiable {
    case focus = "Foco"
    case progress = "Progresso"
    case settings = "Ajustes"

    var id: String { rawValue }
}

struct PomodoroView: View {
    @EnvironmentObject private var store: PomodoroStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @AppStorage("pomodoroAmbientEnabled") private var ambientEnabled = true
    @AppStorage("pomodoroAmbientVolume") private var ambientVolume = 0.35
    @AppStorage("pomodoroAmbientSound") private var ambientSoundRaw = AmbientSound.rain.rawValue

    @StateObject private var soundPlayer = AmbientSoundPlayer()
    @State private var tab: PomodoroTab = .focus

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var ambientSound: AmbientSound { AmbientSound(rawValue: ambientSoundRaw) ?? .rain }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(style: .focus)

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pomodoro")
                                .font(.largeTitle.bold())
                            Text("Uma estrela de cada vez.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("Pomodoro", selection: $tab) {
                            ForEach(PomodoroTab.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch tab {
                        case .focus:
                            focusView
                        case .progress:
                            progressView
                        case .settings:
                            settingsView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 124)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { syncAmbient() }
        .onDisappear { soundPlayer.stop() }
        .onChange(of: store.running) { _, _ in syncAmbient() }
        .onChange(of: store.phase) { _, _ in syncAmbient() }
        .onChange(of: ambientEnabled) { _, _ in syncAmbient() }
        .onChange(of: ambientSoundRaw) { _, _ in syncAmbient() }
        .onChange(of: tab) { _, _ in syncAmbient() }
        .onChange(of: ambientVolume) { _, value in soundPlayer.updateVolume(value) }
    }

    private var focusView: some View {
        VStack(spacing: 13) {
            AnimatedPomodoroArtwork(active: store.running && store.phase == .focus)
                .frame(height: 210)

            Text(store.phase.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.purple)

            Text(timeString(store.remainingSeconds))
                .font(.system(size: 66, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            VStack(spacing: 4) {
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
                roundControl("arrow.counterclockwise", size: 50) {
                    store.reset()
                }

                roundControl(store.running ? "pause.fill" : "play.fill", size: 70, prominent: true) {
                    store.running ? store.pause() : store.start()
                }

                roundControl("forward.end.fill", size: 50) {
                    store.skip()
                }
            }
            .padding(.top, 2)

            ambientQuickControl

            Text("Só focos completos entram no total. Pular ou zerar não registra um pomodoro.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.purple.opacity(0.025), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
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
                Label("Crie seu ambiente", systemImage: "leaf.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.purple)
                Text("Toque em um som para ouvir na hora. Durante o foco, ele continua em loop.")
                    .foregroundStyle(.secondary)

                Toggle("Som durante o foco", isOn: $ambientEnabled)
                    .font(.headline)

                HStack {
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(.purple)
                    Slider(value: $ambientVolume, in: 0...1)
                    Text("\(Int(ambientVolume * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 46)
                }

                if let error = soundPlayer.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if soundPlayer.isPlaying {
                    Label("Prévia tocando", systemImage: "speaker.wave.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(20)
            .background(
                LinearGradient(colors: [.purple.opacity(0.12), .cyan.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
            .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AmbientSound.allCases.filter { $0 != .none }) { sound in
                    Button {
                        ambientSoundRaw = sound.rawValue
                        ambientEnabled = true
                        soundPlayer.play(sound, volume: ambientVolume)
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

    private var totalFocusMinutes: Int {
        store.history.reduce(0) { $0 + $1.durationSeconds / 60 }
    }

    private var lastSevenDays: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
            let minutes = store.history
                .filter { calendar.isDate($0.finishedAt, inSameDayAs: date) }
                .reduce(0) { $0 + $1.durationSeconds / 60 }
            return (formatter.string(from: date), minutes)
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    @ViewBuilder
    private func roundControl(_ icon: String, size: CGFloat, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        if prominent {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .semibold))
                    .frame(width: size, height: size)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.purple)
        } else {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: size, height: size)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
    }

    private func intSetting(_ keyPath: WritableKeyPath<PomodoroSettings, Int>) -> Binding<Int> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { value in
                var draft = store.settings
                draft[keyPath: keyPath] = value
                store.configure(draft)
            }
        )
    }

    private func boolSetting(_ keyPath: WritableKeyPath<PomodoroSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { value in
                var draft = store.settings
                draft[keyPath: keyPath] = value
                store.configure(draft)
            }
        )
    }

    private var ambientQuickControl: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(AmbientSound.allCases.filter { $0 != .none }) { sound in
                    Button {
                        ambientSoundRaw = sound.rawValue
                        ambientEnabled = true
                        soundPlayer.play(sound, volume: ambientVolume)
                    } label: {
                        Label(sound.title, systemImage: sound.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: ambientSound.icon)
                    Text(ambientSound.title)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)

            Button {
                ambientEnabled.toggle()
                syncAmbient()
            } label: {
                Image(systemName: ambientEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(ambientEnabled ? .purple : .secondary)
        }
        .font(.subheadline.weight(.semibold))
        .accessibilityElement(children: .contain)
    }

    private func syncAmbient() {
        let shouldPlay = ambientEnabled && ambientSound != .none && (store.running || tab == .focus || tab == .settings)

        if shouldPlay {
            soundPlayer.play(ambientSound, volume: ambientVolume)
        } else {
            soundPlayer.stop()
        }
    }
}

private struct AnimatedPomodoroArtwork: View {
    let active: Bool
    @State private var floating = false
    @State private var sparkle = false

    var body: some View {
        ZStack {
            if active {
                activeStars

                Image("PomodoroFishing")
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .rotationEffect(.degrees(floating ? 0.55 : -0.55))
                    .offset(y: floating ? -4 : 5)
                    .overlay {
                        FishingLineAnimation()
                    }
            } else {
                Image("PomodoroRest")
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .offset(y: floating ? -3 : 4)
                    .overlay {
                        SaturnRingShimmer()
                    }

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .offset(x: 86, y: -58)
                    .scaleEffect(sparkle ? 1.25 : 0.72)
                    .opacity(sparkle ? 1 : 0.45)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: active)
        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floating)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: sparkle)
        .onAppear {
            floating = true
            sparkle = true
        }
    }

    private var activeStars: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "star.fill" : "sparkle")
                    .font(.system(size: CGFloat(8 + (index % 3) * 3), weight: .semibold))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.yellow : Color.cyan)
                    .opacity(sparkle ? 0.95 : 0.32)
                    .scaleEffect(sparkle ? 1.08 : 0.74)
                    .offset(
                        x: CGFloat([-104, -74, -30, 34, 70, 100, 118][index]),
                        y: CGFloat([46, -52, 70, -72, 32, -20, 68][index]) + (floating ? -5 : 5)
                    )
                    .animation(
                        .easeInOut(duration: 0.75 + Double(index) * 0.11).repeatForever(autoreverses: true),
                        value: sparkle
                    )
            }
        }
    }
}

private struct FishingLineAnimation: View {
    @State private var lowered = false
    @State private var starPulse = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let start = CGPoint(x: width * 0.742, y: height * 0.10)
            let endY = height * (lowered ? 0.63 : 0.42)
            let end = CGPoint(x: width * 0.758, y: endY)

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: start)
                    path.addQuadCurve(
                        to: end,
                        control: CGPoint(x: width * 0.80, y: height * 0.30)
                    )
                }
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.95), .cyan.opacity(0.85)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                )
                .shadow(color: .cyan.opacity(0.6), radius: 3)

                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.8), radius: 5)
                    .scaleEffect(starPulse ? 1.18 : 0.82)
                    .position(end)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: true)) {
                lowered = true
            }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                starPulse = true
            }
        }
    }
}

private struct SaturnRingShimmer: View {
    @State private var travel = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            Ellipse()
                .trim(from: travel ? 0.69 : 0.04, to: travel ? 0.91 : 0.26)
                .stroke(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.95), .cyan.opacity(0.75), .purple.opacity(0.55), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: max(2.5, height * 0.018), lineCap: .round)
                )
                .frame(width: width * 0.82, height: height * 0.31)
                .rotationEffect(.degrees(-8))
                .position(x: width * 0.53, y: height * 0.64)
                .blendMode(.screen)
                .shadow(color: .cyan.opacity(0.35), radius: 4)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                travel = true
            }
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

    private var tint: Color {
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
                if selected {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .foregroundStyle(.purple)
                }
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
