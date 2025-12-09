import CoreGraphics
import Foundation

struct RecordingSession: Identifiable, Hashable {
    static let incompleteMarkerFilename = ".session_incomplete"

    struct DeviceInfo: Hashable {
        let model: String
        let os: String
    }

    struct CameraInfo: Hashable {
        let position: String
        let preset: String
    }

    struct VideoInfo: Hashable {
        let fileName: String
        let codec: String
        let size: CGSize?
        let fps: Double?
        let url: URL
        let fileSizeBytes: Int64?
    }

    struct PoseInfo: Hashable {
        let fileName: String
        let jointSet: String
        let coords: String
        let url: URL
        let fileSizeBytes: Int64?
    }

    let id: String
    let createdAt: Date
    let directoryURL: URL
    let device: DeviceInfo
    let camera: CameraInfo
    let video: VideoInfo?
    let pose: PoseInfo?
    let hasIncompleteMarker: Bool

    var videoURL: URL? { video?.url }
    var poseURL: URL? { pose?.url }
    var isComplete: Bool { !hasIncompleteMarker && video != nil && pose != nil }
}
