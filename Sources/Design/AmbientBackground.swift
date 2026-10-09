import SwiftUI

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .secondarySystemBackground),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.blue.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -150, y: -260)

            Circle()
                .fill(.purple.opacity(0.09))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: 160, y: 300)
        }
        .ignoresSafeArea()
    }
}
