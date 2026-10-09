import AVFoundation
import Foundation

@MainActor
final class AmbientSoundPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var lastError: String?

    private var player: AVAudioPlayer?

    func play(_ sound: AmbientSound, volume: Double) {
        stop()
        guard sound != .none else { return }

        let url = Bundle.main.url(forResource: sound.resourceName, withExtension: "m4a")
            ?? Bundle.main.url(forResource: sound.resourceName, withExtension: "m4a", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: sound.resourceName, withExtension: "m4a", subdirectory: "Resources/Sounds")

        guard let url else {
            lastError = "O áudio \(sound.title) não foi encontrado no aplicativo."
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(min(max(volume, 0), 1))
            player.prepareToPlay()
            isPlaying = player.play()
            self.player = player
            lastError = isPlaying ? nil : "Não foi possível iniciar \(sound.title)."
        } catch {
            self.player = nil
            isPlaying = false
            lastError = error.localizedDescription
        }
    }

    func updateVolume(_ volume: Double) {
        player?.volume = Float(min(max(volume, 0), 1))
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}

enum AmbientSound: String, CaseIterable, Identifiable {
    case none, clock, wind, rain, storm, fire, library, room
    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Sem som"
        case .clock: return "Relógio"
        case .wind: return "Ar e vento"
        case .rain: return "Chuva"
        case .storm: return "Tempestade"
        case .fire: return "Lareira"
        case .library: return "Biblioteca"
        case .room: return "Ambiente"
        }
    }

    var subtitle: String {
        switch self {
        case .none: return "Silêncio"
        case .clock: return "Tique-taque ritmado"
        case .wind: return "Uma brisa constante"
        case .rain: return "Gotas para concentrar"
        case .storm: return "Chuva e trovões"
        case .fire: return "Madeira crepitando"
        case .library: return "Páginas e sala de estudos"
        case .room: return "Ruído ambiente suave"
        }
    }

    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .clock: return "clock.fill"
        case .wind: return "wind"
        case .rain: return "drop.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .fire: return "flame.fill"
        case .library: return "books.vertical.fill"
        case .room: return "waveform"
        }
    }

    var resourceName: String {
        switch self {
        case .none: return ""
        case .clock: return "ambient_clock"
        case .wind: return "ambient_wind"
        case .rain: return "ambient_rain"
        case .storm: return "ambient_storm"
        case .fire: return "ambient_fire"
        case .library: return "ambient_library"
        case .room: return "ambient_room"
        }
    }
}
