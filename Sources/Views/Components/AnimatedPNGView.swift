import ImageIO
import SwiftUI
import UIKit

/// Displays the Pomodoro APNG resources as native UIImage animation frames.
/// APNG keeps the original alpha channel, so the artwork stays transparent
/// over Liquid Glass instead of receiving the black GIF matte.
struct AnimatedPNGView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = false
        view.backgroundColor = .clear
        view.accessibilityIdentifier = resourceName
        view.image = Self.animatedImage(named: resourceName)
        view.startAnimating()
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard uiView.accessibilityIdentifier != resourceName else {
            if !uiView.isAnimating { uiView.startAnimating() }
            return
        }

        uiView.accessibilityIdentifier = resourceName
        uiView.image = Self.animatedImage(named: resourceName)
        uiView.startAnimating()
    }

    private static func animatedImage(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var frames: [UIImage] = []
        frames.reserveCapacity(count)

        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up))
        }

        guard let first = frames.first else { return nil }
        guard frames.count > 1 else { return first }

        // 12 frames × 0.13 s ≈ 1.56 s per seamless loop.
        return UIImage.animatedImage(with: frames, duration: Double(frames.count) * 0.13)
    }
}
