import SwiftUI
import UIKit

struct PosePreviewView: UIViewRepresentable {
    let poseFrame: PoseFrame

    func makeUIView(context: Context) -> PoseImageView {
        PoseImageView()
    }

    func updateUIView(_ uiView: PoseImageView, context: Context) {
        guard poseFrame.imageSize.width > 0, poseFrame.imageSize.height > 0 else {
            uiView.image = nil
            return
        }

        let backgroundSize = CGSize(width: poseFrame.imageSize.width, height: poseFrame.imageSize.height)
        guard let cgImage = Self.makePlaceholderImage(size: backgroundSize) else {
            uiView.image = nil
            return
        }

        uiView.show(
            scaledPose: Pose(),
            studentPose: poseFrame.pose,
            on: cgImage,
            isFrameDraw: false
        )
    }

    private static func makePlaceholderImage(size: CGSize) -> CGImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }
}
