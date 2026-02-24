import CoreGraphics
import CoreMedia
import Foundation

/// JSON書き出し用のユーティリティ。
/// Pose構造体をセッション録画で利用するNDJSON形式へシリアライズする。
enum PoseSerialization {
    struct JointPayload: Codable {
        let x: Double
        let y: Double
        let c: Double
    }

    struct FramePayload: Codable {
        let tMs: Int
        let imgSize: [Int]
        let score: Double
        let joints: [String: JointPayload]

        enum CodingKeys: String, CodingKey {
            case tMs = "t_ms"
            case imgSize = "img_size"
            case score
            case joints
        }
    }

    /// PoseをFramePayloadへ変換する。
    static func makeFramePayload(pose: Pose, timestampMs: Int, imageSize: CGSize) -> FramePayload {
        let width = max(Int(imageSize.width.rounded()), 1)
        let height = max(Int(imageSize.height.rounded()), 1)
        let joints = jointsDictionary(from: pose, imageSize: imageSize)
        return FramePayload(
            tMs: timestampMs,
            imgSize: [width, height],
            score: pose.confidence,
            joints: joints
        )
    }

    /// FramePayloadをUTF-8のJSON Dataへエンコードする。
    static func encodeFrame(_ frame: FramePayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return try encoder.encode(frame)
    }

    /// タイムスタンプ（ms）を計算する。
    static func timestampMs(for timestamp: CMTime, relativeTo reference: CMTime) -> Int {
        let delta = CMTimeSubtract(timestamp, reference)
        let seconds = CMTimeGetSeconds(delta)
        guard seconds.isFinite else { return 0 }
        return Int((seconds * 1000.0).rounded())
    }

    /// NDJSON 1行分のDataを返す（終端に改行コード含む）。
    static func makeNDJSONLine(pose: Pose, timestampMs: Int, imageSize: CGSize) throws -> Data {
        let payload = makeFramePayload(pose: pose, timestampMs: timestampMs, imageSize: imageSize)
        var data = try encodeFrame(payload)
        data.append(0x0a) // "\n"
        return data
    }

    private static func jointsDictionary(from pose: Pose, imageSize: CGSize) -> [String: JointPayload] {
        var result: [String: JointPayload] = [:]
        let inputCoordinates = detectInputCoordinates(for: pose, imageSize: imageSize)
        for jointName in Joint.Name.allCases {
            let key = cocoKey(for: jointName)
            let joint = pose[jointName]
            let normalized: (x: Double, y: Double)
            switch inputCoordinates {
            case .normalized:
                normalized = (x: clamp(Double(joint.position.x)), y: clamp(Double(joint.position.y)))
            case .pixel:
                normalized = normalize(joint.position, imageSize: imageSize)
            }
            result[key] = JointPayload(x: normalized.x, y: normalized.y, c: max(0.0, min(1.0, joint.confidence)))
        }
        return result
    }

    private enum InputCoordinates {
        case pixel
        case normalized
    }

    private static func detectInputCoordinates(for pose: Pose, imageSize: CGSize) -> InputCoordinates {
        // ML Kit由来の座標が「ピクセル」か「正規化済み」か、実データから推定して二重正規化を防ぐ。
        // すべての関節が 0..1 付近に収まっている場合は正規化済みとみなす。
        let positions = pose.joints.values
            .filter { $0.isValid }
            .map { $0.position }

        guard !positions.isEmpty else { return .pixel }

        let maxValue = positions
            .flatMap { [abs($0.x), abs($0.y)] }
            .max() ?? 0

        // 画像サイズが極端に小さいケースは想定外のため pixel 扱いに倒す。
        guard imageSize.width > 2, imageSize.height > 2 else { return .pixel }

        return maxValue <= 1.5 ? .normalized : .pixel
    }

    private static func normalize(_ point: CGPoint, imageSize: CGSize) -> (x: Double, y: Double) {
        let width = max(imageSize.width, 1)
        let height = max(imageSize.height, 1)
        let normalizedX = Double(point.x / width)
        let normalizedY = Double(point.y / height)
        return (
            x: clamp(normalizedX),
            y: clamp(normalizedY)
        )
    }

    private static func clamp(_ value: Double) -> Double {
        if value.isNaN || !value.isFinite {
            return 0.0
        }
        return min(max(value, 0.0), 1.0)
    }

    private static func cocoKey(for joint: Joint.Name) -> String {
        switch joint {
        case .nose: return "nose"
        case .leftEye: return "leftEye"
        case .rightEye: return "rightEye"
        case .leftEar: return "leftEar"
        case .rightEar: return "rightEar"
        case .leftShoulder: return "leftShoulder"
        case .rightShoulder: return "rightShoulder"
        case .leftElbow: return "leftElbow"
        case .rightElbow: return "rightElbow"
        case .leftWrist: return "leftWrist"
        case .rightWrist: return "rightWrist"
        case .leftHip: return "leftHip"
        case .rightHip: return "rightHip"
        case .leftKnee: return "leftKnee"
        case .rightKnee: return "rightKnee"
        case .leftAnkle: return "leftAnkle"
        case .rightAnkle: return "rightAnkle"
        }
    }
}
