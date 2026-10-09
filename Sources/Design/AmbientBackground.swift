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
                    Color(uiColor: .secondarySystemBackground).opacity(0.92),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(accents[0].opacity(0.14))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: -155, y: -285)

            Circle()
                .fill(accents[1].opacity(0.11))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: 175, y: 90)

            Circle()
                .fill(accents[2].opacity(0.08))
                .frame(width: 330, height: 330)
                .blur(radius: 105)
                .offset(x: 80, y: 390)
        }
        .ignoresSafeArea()
    }
}
