import AVFoundation
import AVKit
import PDFKit
import SwiftUI

struct DrivePlayerView: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @StateObject private var loader = DriveContentLoader()
    @State private var retryID = 0

    let item: StudyItem

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Preparando conteúdo…")
                        .font(.headline)
                    Text("Usando a conta Google já conectada ao Kepleræ.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready(let url):
                NativeStudyContentView(item: item, localURL: url)

            case .failed(let message):
                ContentUnavailableView {
                    Label("Não foi possível abrir", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(message)
                } actions: {
                    Button("Tentar novamente") {
                        loader.reset()
                        retryID += 1
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task(id: "\(item.id)-\(retryID)") {
            await loader.load(item: item, auth: auth)
        }
    }
}

private struct NativeStudyContentView: View {
    let item: StudyItem
    let localURL: URL

    var body: some View {
        switch item.type {
        case .pdf:
            PDFDocumentView(url: localURL)
        case .lesson:
            VideoStudyPlayer(url: localURL)
        case .audio:
            AudioStudyPlayer(url: localURL, title: item.title)
        }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

private struct VideoStudyPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .background(.black)
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: url)
                }
            }
            .onDisappear {
                player?.pause()
            }
    }
}

private struct AudioStudyPlayer: View {
    let url: URL
    let title: String

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 92, weight: .regular))
                .foregroundStyle(.purple.gradient)
                .symbolEffect(.pulse, isActive: isPlaying)

            VStack(spacing: 7) {
                Text(title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                Text(isPlaying ? "Reproduzindo" : "Pronto para ouvir")
                    .foregroundStyle(.secondary)
            }

            Button {
                guard let player else { return }
                if isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 76, height: 76)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.purple)

            Spacer()
        }
        .padding(28)
        .onAppear {
            if player == nil {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }
}
