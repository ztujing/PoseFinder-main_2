import SwiftUI
import UIKit
import AVFoundation

struct PosePreviewView: UIViewRepresentable {
    let poseFrame: PoseFrame
    let aspectRatioSize: CGSize?

    init(poseFrame: PoseFrame, aspectRatioSize: CGSize? = nil) {
        self.poseFrame = poseFrame
        self.aspectRatioSize = aspectRatioSize
    }

    func makeUIView(context: Context) -> PoseImageView {
        let view = PoseImageView(frame: .zero)
        view.useLegacyJointRendering = false
        return view
    }

    func updateUIView(_ uiView: PoseImageView, context: Context) {
        // UIViewRepresentableは親のレイアウト結果（bounds）を信頼して描画サイズを決める。
        // これにより、動画の表示領域に合わせてPoseを同じ座標系へ収められる。
        let destinationSize = uiView.bounds.size
        guard destinationSize.width > 0, destinationSize.height > 0 else {
            uiView.image = nil
            return
        }
        guard poseFrame.imageSize.width > 0, poseFrame.imageSize.height > 0 else {
            uiView.image = nil
            return
        }

        guard let cgImage = Self.makePlaceholderImage(size: destinationSize) else {
            uiView.image = nil
            return
        }

        let videoAspectSize: CGSize = {
            guard let size = aspectRatioSize, size.width > 0, size.height > 0 else {
                return poseFrame.imageSize
            }
            return size
        }()
        let mappedStudentPose = Self.mapPoseToDestination(
            poseFrame.pose,
            normalizationSize: poseFrame.imageSize,
            aspectRatioSize: videoAspectSize,
            destinationSize: destinationSize
        )

        uiView.show(
            scaledPose: Pose(),
            studentPose: mappedStudentPose,
            on: cgImage,
            isFrameDraw: false
        )
    }

    private static func makePlaceholderImage(size: CGSize) -> CGImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        // ここでの size は「points」（= UIView の bounds）として扱う。
        // CGImage の pixel サイズ（frame.width/height）をそのまま UIGraphicsImageRenderer の size に渡すため、
        // scale を 1 に固定して points/pixels の不一致で左上に縮む問題を避ける。
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }

    private static func mapPoseToDestination(_ pose: Pose,
                                             normalizationSize: CGSize,
                                             aspectRatioSize: CGSize,
                                             destinationSize: CGSize) -> Pose {
        let insideRect = CGRect(origin: .zero, size: destinationSize)
        let fitted = AVMakeRect(aspectRatio: aspectRatioSize, insideRect: insideRect)

        let inputCoordinates = detectInputCoordinates(for: pose, normalizationSize: normalizationSize)
        var mapped = Pose()
        for (name, joint) in pose.joints {
            var newJoint = mapped[name]
            newJoint.confidence = joint.confidence
            // 旧セッション互換: score が未設定(0)の場合は confidence を強調表示用スコアとして使う。
            newJoint.score = joint.score > 0 ? joint.score : joint.confidence
            newJoint.isValid = joint.isValid

            guard joint.isValid else {
                mapped[name] = newJoint
                continue
            }

            let nx: CGFloat
            let ny: CGFloat
            switch inputCoordinates {
            case .normalized:
                nx = clamp01(joint.position.x)
                ny = clamp01(joint.position.y)
            case .pixel:
                nx = normalizationSize.width > 0 ? joint.position.x / normalizationSize.width : 0
                ny = normalizationSize.height > 0 ? joint.position.y / normalizationSize.height : 0
            }
            newJoint.position = CGPoint(
                x: fitted.origin.x + nx * fitted.size.width,
                y: fitted.origin.y + ny * fitted.size.height
            )
            mapped[name] = newJoint
        }

        mapped.confidence = pose.confidence
        mapped.score = pose.score > 0 ? pose.score : pose.confidence
        return mapped
    }

    private enum InputCoordinates {
        case pixel
        case normalized
    }

    private static func detectInputCoordinates(for pose: Pose, normalizationSize: CGSize) -> InputCoordinates {
        // 保存済みデータ互換:
        // Joint.position が「ピクセル」か「正規化済み」かを推定し、二重正規化による左上寄り縮小を防ぐ。
        let positions = pose.joints.values
            .filter { $0.isValid }
            .map { $0.position }

        guard !positions.isEmpty else { return .pixel }

        let maxValue = positions
            .flatMap { [abs($0.x), abs($0.y)] }
            .max() ?? 0

        // normalizationSize が極端に小さい場合は判定が不安定なので pixel 扱いに倒す。
        guard normalizationSize.width > 2, normalizationSize.height > 2 else { return .pixel }

        return maxValue <= 1.5 ? .normalized : .pixel
    }

    private static func clamp01(_ value: CGFloat) -> CGFloat {
        if value.isNaN || !value.isFinite {
            return 0
        }
        return min(max(value, 0), 1)
    }
}
