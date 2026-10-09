import ImageIO
import SwiftUI
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = false
        view.backgroundColor = .clear
        view.image = Self.animatedImage(named: resourceName)
        view.startAnimating()
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard uiView.accessibilityIdentifier != resourceName else { return }
        uiView.accessibilityIdentifier = resourceName
        uiView.image = Self.animatedImage(named: resourceName)
        uiView.startAnimating()
    }

    private static func animatedImage(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        frames.reserveCapacity(count)

        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up))

            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let unclamped = gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double
            let clamped = gif?[kCGImagePropertyGIFDelayTime] as? Double
            duration += max(unclamped ?? clamped ?? 0.1, 0.04)
        }

        guard !frames.isEmpty else { return nil }
        if frames.count == 1 { return frames[0] }
        return UIImage.animatedImage(with: frames, duration: duration)
    }
}
