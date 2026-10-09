import Foundation

@MainActor
final class PomodoroStore: ObservableObject {
    @Published var settings: PomodoroSettings
    @Published private(set) var phase: PomodoroPhase
    @Published private(set) var running: Bool
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var cycle: Int
    @Published private(set) var history: [FocusRecord]

    private var timer: Timer?
    private var deadline: Date?
    private let key = "keplerae.pomodoro.v1"

    private struct Payload: Codable {
        var settings: PomodoroSettings
        var phase: PomodoroPhase
        var running: Bool
        var remainingSeconds: Int
        var cycle: Int
        var history: [FocusRecord]
        var deadline: Date?
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key), let p = try? JSONDecoder().decode(Payload.self, from: data) {
            settings = p.settings; phase = p.phase; running = p.running; remainingSeconds = p.remainingSeconds
            cycle = p.cycle; history = p.history; deadline = p.deadline
        } else {
            settings = PomodoroSettings(); phase = .focus; running = false; remainingSeconds = 25 * 60; cycle = 0; history = []; deadline = nil
        }
        if running { startTicker(); tick() }
    }

    func start() {
        guard !running else { return }
        running = true
        deadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startTicker(); save()
    }

    func pause() { tick(); running = false; timer?.invalidate(); timer = nil; deadline = nil; save() }

    func reset() {
        running = false; timer?.invalidate(); timer = nil; deadline = nil
        remainingSeconds = settings.minutes(for: phase) * 60; save()
    }

    func skip() {
        running = false; timer?.invalidate(); timer = nil; deadline = nil
        phase = phase == .focus ? .shortBreak : .focus
        remainingSeconds = settings.minutes(for: phase) * 60; save()
    }

    func configure(_ value: PomodoroSettings) {
        settings = value
        if !running { phase = .focus; cycle = 0; remainingSeconds = value.focusMinutes * 60 }
        save()
    }

    func replace(settings: PomodoroSettings, history: [FocusRecord]) { self.settings = settings; self.history = history; reset() }

    private func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
    }

    private func tick() {
        guard running, let deadline else { return }
        remainingSeconds = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        if remainingSeconds == 0 { finishPhase() }
    }

    private func finishPhase() {
        let finished = phase
        if finished == .focus {
            history.append(FocusRecord(id: UUID(), finishedAt: .now, durationSeconds: settings.focusMinutes * 60))
            cycle += 1
            phase = cycle >= settings.cycles ? .longBreak : .shortBreak
        } else {
            if finished == .longBreak { cycle = 0 }
            phase = .focus
        }
        running = false; timer?.invalidate(); timer = nil; deadline = nil
        remainingSeconds = settings.minutes(for: phase) * 60
        save()
        if settings.autoAdvance { start() }
    }

    private func save() {
        let payload = Payload(settings: settings, phase: phase, running: running, remainingSeconds: remainingSeconds,
                              cycle: cycle, history: history, deadline: deadline)
        if let data = try? JSONEncoder().encode(payload) { UserDefaults.standard.set(data, forKey: key) }
    }
}
