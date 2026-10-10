@preconcurrency import AVFoundation
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
                loadingView("Preparando conteúdo…")

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

    private func loadingView(_ title: String) -> some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.headline)
            Text("Usando a conta Google já conectada ao Kepleræ.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NativeStudyContentView: View {
    let item: StudyItem
    let content: DriveContentLoader.PreparedContent

    var body: some View {
        switch (item.type, content) {
        case (.pdf, .local(let url)):
            PDFReaderView(url: url)

        case (.lesson, .stream(let stream)):
            VideoStudyPlayer(item: item, stream: stream)

        case (.audio, .stream(let stream)):
            AudioStudyPlayer(item: item, stream: stream)

        case (.lesson, .local(let url)):
            LocalVideoPlayer(url: url)

        case (.audio, .local(let url)):
            LocalAudioPlayer(url: url, title: item.title)

        case (.pdf, .stream):
            ContentUnavailableView("PDF indisponível", systemImage: "doc.text")
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
                Label("Tela cheia", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 42)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
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

private enum MediaLoadState: Equatable {
    case preparing
    case ready
    case fallback
    case failed(String)
}

private struct VideoStudyPlayer: View {
    let item: StudyItem
    let stream: DriveStreamDescriptor

    @State private var player: AVPlayer?
    @State private var state: MediaLoadState = .preparing

    var body: some View {
        ZStack {
            Color.black

            if let player {
                VideoPlayer(player: player)
            }

            switch state {
            case .preparing:
                mediaOverlay(title: "Conectando ao vídeo…", subtitle: "Tentando iniciar o vídeo direto do Drive antes de usar o cache.")
            case .fallback:
                mediaOverlay(title: "Otimizando reprodução…", subtitle: "Preparando uma cópia local em cache para iniciar com estabilidade.")
            case .failed(let message):
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                    Text("Não foi possível reproduzir o vídeo")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .foregroundStyle(.white)
            case .ready:
                EmptyView()
            }
        }
        .task(id: stream.url) {
            await prepareStream()
        }
        .onDisappear {
            player?.pause()
        }
    }

    @ViewBuilder
    private func mediaOverlay(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(.white)
                .controlSize(.large)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(24)
    }

    @MainActor
    private func prepareStream() async {
        state = .preparing
        let streamPlayer = makeAuthenticatedPlayer(stream: stream)
        player = streamPlayer

        for _ in 0..<16 {
            guard !Task.isCancelled else { return }
            guard let item = streamPlayer.currentItem else { break }

            switch item.status {
            case .readyToPlay:
                state = .ready
                return
            case .failed:
                await fallbackToLocal()
                return
            case .unknown:
                break
            @unknown default:
                break
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        await fallbackToLocal()
    }

    @MainActor
    private func fallbackToLocal() async {
        guard !Task.isCancelled else { return }
        state = .fallback

        do {
            let localURL = try await DriveContentLoader.download(item: item, accessToken: stream.accessToken)
            guard !Task.isCancelled else { return }
            let localPlayer = AVPlayer(url: localURL)
            localPlayer.automaticallyWaitsToMinimizeStalling = true
            player = localPlayer
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private struct AudioStudyPlayer: View {
    let item: StudyItem
    let stream: DriveStreamDescriptor

    @State private var player: AVPlayer?
    @State private var state: MediaLoadState = .preparing
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(.purple.gradient)
                .symbolEffect(.pulse, isActive: isPlaying)

            VStack(spacing: 7) {
                Text(item.title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                switch state {
                case .preparing:
                    Text("Conectando ao áudio…")
                        .foregroundStyle(.secondary)
                case .fallback:
                    Text("Preparando áudio em cache…")
                        .foregroundStyle(.secondary)
                case .ready:
                    Text(isPlaying ? "Reproduzindo" : "Pronto para ouvir")
                        .foregroundStyle(.secondary)
                case .failed(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                guard state == .ready, let player else { return }
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
            .disabled(state != .ready)

            if state == .preparing || state == .fallback {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()
        }
        .padding(28)
        .task(id: stream.url) {
            await prepareStream()
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }

    @MainActor
    private func prepareStream() async {
        state = .preparing
        let streamPlayer = makeAuthenticatedPlayer(stream: stream)
        player = streamPlayer

        for _ in 0..<12 {
            guard !Task.isCancelled else { return }
            guard let item = streamPlayer.currentItem else { break }

            switch item.status {
            case .readyToPlay:
                state = .ready
                return
            case .failed:
                await fallbackToLocal()
                return
            case .unknown:
                break
            @unknown default:
                break
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        await fallbackToLocal()
    }

    @MainActor
    private func fallbackToLocal() async {
        guard !Task.isCancelled else { return }
        state = .fallback

        do {
            let localURL = try await DriveContentLoader.download(item: item, accessToken: stream.accessToken)
            guard !Task.isCancelled else { return }
            player = AVPlayer(url: localURL)
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

@MainActor
private func makeAuthenticatedPlayer(stream: DriveStreamDescriptor) -> AVPlayer {
    // AVPlayer requires byte-range requests for fast startup. The bearer token is
    // attached to every request made by the URL asset, while the Drive endpoint
    // keeps support for Range responses.
    let headers = [
        "Authorization": "Bearer \(stream.accessToken)",
        "Accept": stream.mimeType
    ]

    let asset = AVURLAsset(
        url: stream.url,
        options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers,
            AVURLAssetAllowsCellularAccessKey: true,
            AVURLAssetAllowsConstrainedNetworkAccessKey: true,
            AVURLAssetAllowsExpensiveNetworkAccessKey: true
        ]
    )

    let item = AVPlayerItem(asset: asset)
    item.preferredForwardBufferDuration = 3

    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = true
    return player
}

private struct LocalVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .background(.black)
            .onAppear {
                guard player == nil else { return }
                player = AVPlayer(url: url)
            }
            .onDisappear { player?.pause() }
    }
}

private struct LocalAudioPlayer: View {
    let url: URL
    let title: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(.purple.gradient)
                .symbolEffect(.pulse, isActive: isPlaying)
            Text(title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
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
            if player == nil { player = AVPlayer(url: url) }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }
}
