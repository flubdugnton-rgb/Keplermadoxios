import SwiftUI

enum AmbientBackgroundStyle {
    case standard, welcome, focus, library
}

struct AmbientBackground: View {
    var style: AmbientBackgroundStyle = .standard

    private var accents: [Color] {
        switch style {
        case .standard: return [.blue, .purple, .pink]
        case .welcome: return [.cyan, .indigo, .pink]
        case .focus: return [.purple, .cyan, .indigo]
        case .library: return [.mint, .cyan, .blue]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .secondarySystemBackground).opacity(0.78),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [accents[0].opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 390
            )

            RadialGradient(
                colors: [accents[1].opacity(0.14), .clear],
                center: .trailing,
                startRadius: 8,
                endRadius: 350
            )

            RadialGradient(
                colors: [accents[2].opacity(0.10), .clear],
                center: .bottom,
                startRadius: 8,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}
