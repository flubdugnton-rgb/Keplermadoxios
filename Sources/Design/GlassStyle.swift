import SwiftUI

struct KepleraeGlassModifier: ViewModifier {
    let intensity: Double
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        let normalized = min(max(intensity, 0), 1)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let material: Glass = {
            if normalized <= 0.05 { return .identity }
            if normalized < 0.45 { return .clear }
            return .regular
        }()

        content
            .glassEffect(material.interactive(interactive), in: shape)
            .overlay {
                shape.stroke(
                    Color.white.opacity(0.06 + (0.24 * normalized)),
                    lineWidth: 0.7 + (0.8 * normalized)
                )
            }
            .shadow(
                color: Color.black.opacity(0.03 + (0.11 * normalized)),
                radius: 4 + (16 * normalized),
                y: 2 + (7 * normalized)
            )
    }
}

extension View {
    func kepleraeGlass(
        intensity: Double,
        cornerRadius: CGFloat = 28,
        interactive: Bool = true
    ) -> some View {
        modifier(
            KepleraeGlassModifier(
                intensity: intensity,
                cornerRadius: cornerRadius,
                interactive: interactive
            )
        )
    }
}
