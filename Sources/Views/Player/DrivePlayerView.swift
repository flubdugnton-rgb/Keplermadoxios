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
                    Text(item.type == .lesson ? "Abrindo vídeo…" : "Preparando conteúdo…")
                        .font(.headline)
                    Text(item.type == .lesson ? "O vídeo começa por streaming, sem esperar o download completo." : "Usando a conta Google já conectada ao Kepleræ.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready(let content):
                NativeStudyContentView(item: item, content: content)

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
    let content: DriveContentLoader.PreparedContent

    private var url: URL {
        switch content {
        case .local(let url), .stream(let url): return url
        }
    }

    var body: some View {
        switch item.type {
        case .pdf:
            PDFReaderView(url: url)
        case .lesson:
            VideoStudyPlayer(url: url)
        case .audio:
            AudioStudyPlayer(url: url, title: item.title)
        }
    }
}

private struct PDFReaderView: View {
    let url: URL
    @State private var showFullscreen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PDFDocumentCanvas(url: url)

            Button {
                showFullscreen = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .padding(12)
            .accessibilityLabel("Abrir PDF em tela cheia")
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            ZStack(alignment: .topTrailing) {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                PDFDocumentCanvas(url: url)
                    .ignoresSafeArea(edges: .bottom)

                Button {
                    showFullscreen = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .padding(.top, 12)
                .padding(.trailing, 14)
                .accessibilityLabel("Fechar tela cheia")
            }
        }
    }
}

private struct PDFDocumentCanvas: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.pageShadowsEnabled = true
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
                guard player == nil else { return }
                let item = AVPlayerItem(url: url)
                item.preferredForwardBufferDuration = 2
                item.preferredPeakBitRate = 0
                let newPlayer = AVPlayer(playerItem: item)
                newPlayer.automaticallyWaitsToMinimizeStalling = false
                player = newPlayer
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
                .font(.system(size: 92))
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
                if isPlaying { player.pause() } else { player.play() }
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
            guard player == nil else { return }
            let item = AVPlayerItem(url: url)
            item.preferredForwardBufferDuration = 2
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            player = newPlayer
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }
}
