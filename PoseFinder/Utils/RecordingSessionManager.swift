import AVFoundation
import CoreMedia
import Foundation
import UIKit

/// 撮影セッションの動画・Poseデータを同期保存するマネージャ。
final class RecordingSessionManager {
    struct Options {
        var isRecordingEnabled: Bool = true
        var isPoseNDJSONEnabled: Bool = true
    }

    enum RecordingError: Error {
        case alreadyRecording
        case notRecording
        case writerSetupFailed
        case directoryCreationFailed
        case poseWriterCreationFailed
    }

    private final class SessionState {
        let sessionId: String
        let directoryURL: URL
        let createdAt: Date
        let cameraPosition: AVCaptureDevice.Position
        let sessionPreset: AVCaptureSession.Preset

        var assetWriter: AVAssetWriter?
        var videoInput: AVAssetWriterInput?
        var poseWriter: PoseNDJSONWriter?

        var hasStartedWriting = false
        var firstVideoTimestamp: CMTime?
        var lastVideoTimestamp: CMTime?
        var frameCount: Int64 = 0
        var videoDimensions: CMVideoDimensions?
        var isStopping = false

        var metadata: SessionMetadata

        init(sessionId: String,
             directoryURL: URL,
             cameraPosition: AVCaptureDevice.Position,
             sessionPreset: AVCaptureSession.Preset,
             poseWriter: PoseNDJSONWriter?,
             metadata: SessionMetadata) {
            self.sessionId = sessionId
            self.directoryURL = directoryURL
            self.createdAt = Date()
            self.cameraPosition = cameraPosition
            self.sessionPreset = sessionPreset
            self.poseWriter = poseWriter
            self.metadata = metadata
        }
    }

    private struct SessionMetadata: Codable {
        struct Device: Codable {
            let model: String
            let os: String
        }

        struct Camera: Codable {
            let position: String
            let preset: String
        }

        struct Video: Codable {
            let file: String
            let codec: String
            var size: [Int]?
            var fps: Double?
        }

        struct PoseInfo: Codable {
            let file: String
            let jointSet: String
            let coords: String
        }

        let schemaVersion: Int
        let sessionId: String
        let createdAt: String
        let device: Device
        let camera: Camera
        var video: Video
        let pose: PoseInfo
    }

    private final class PoseNDJSONWriter {
        private let handle: FileHandle
        private let queue = DispatchQueue(label: "com.posefinder.pose-writer", qos: .utility)

        init(fileURL: URL) throws {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: fileURL.path) {
                let created = fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
                if !created {
                    throw RecordingError.poseWriterCreationFailed
                }
            }
            handle = try FileHandle(forWritingTo: fileURL)
            if #available(iOS 13.4, *) {
                try handle.seekToEnd()
            } else {
                handle.seekToEndOfFile()
            }
        }

        func append(_ data: Data) {
            queue.async { [weak self] in
                do {
                    guard let handle = self?.handle else { return }
                    if #available(iOS 13.4, *) {
                        try handle.write(contentsOf: data)
                    } else {
                        handle.write(data)
                    }
                } catch {
                    print("PoseNDJSONWriter append failed: \(error)")
                }
            }
        }

        func close() {
            queue.sync { [weak self] in
                do {
                    guard let handle = self?.handle else { return }
                    if #available(iOS 13.4, *) {
                        try handle.close()
                    } else {
                        handle.closeFile()
                    }
                } catch {
                    print("PoseNDJSONWriter close failed: \(error)")
                }
            }
        }
    }

    var options = Options()

    private let queue = DispatchQueue(label: "com.posefinder.recording-session", qos: .userInitiated)
    private let fileManager = FileManager.default
    private var state: SessionState?
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private enum Constants {
        static let sessionsDirectoryName = "Sessions"
        static let videoFilename = "video.mp4"
        static let poseFilename = "pose.ndjson"
        static let metadataFilename = "session.json"
        static let videoCodec = "h264"
        static let poseJointSet = "coco17"
        static let poseCoords = "normalized"
    }

    // MARK: - Public API

    func start(cameraPosition: AVCaptureDevice.Position, preset: AVCaptureSession.Preset) throws {
        guard options.isRecordingEnabled else { return }

        try queue.sync {
            guard state == nil else { throw RecordingError.alreadyRecording }
            let sessionId = Self.makeSessionId()
            let sessionsRoot = try makeSessionsRoot()
            let directory = sessionsRoot.appendingPathComponent(sessionId, isDirectory: true)
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw RecordingError.directoryCreationFailed
            }

            let metadata = makeMetadata(sessionId: sessionId,
                                        cameraPosition: cameraPosition,
                                        preset: preset)
            var poseWriter: PoseNDJSONWriter? = nil
            if options.isPoseNDJSONEnabled {
                let poseURL = directory.appendingPathComponent(Constants.poseFilename)
                poseWriter = try PoseNDJSONWriter(fileURL: poseURL)
            }

            state = SessionState(sessionId: sessionId,
                                 directoryURL: directory,
                                 cameraPosition: cameraPosition,
                                 sessionPreset: preset,
                                 poseWriter: poseWriter,
                                 metadata: metadata)
        }
    }

    func appendVideo(sampleBuffer: CMSampleBuffer) {
        guard options.isRecordingEnabled else { return }
        queue.async { [weak self] in
            guard let self = self, let state = self.state, !state.isStopping else { return }
            do {
                try self.prepareAssetWriterIfNeeded(using: sampleBuffer, state: state)
            } catch {
                print("RecordingSessionManager writer setup failed: \(error)")
                return
            }

            guard let writer = state.assetWriter, let input = state.videoInput else { return }

            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            if !state.hasStartedWriting {
                writer.startWriting()
                writer.startSession(atSourceTime: timestamp)
                state.firstVideoTimestamp = timestamp
                state.hasStartedWriting = true
            }

            if input.isReadyForMoreMediaData {
                if !input.append(sampleBuffer) {
                    if let error = writer.error {
                        print("RecordingSessionManager append failed: \(error)")
                    } else {
                        print("RecordingSessionManager append failed: Unknown error")
                    }
                }
            }

            state.frameCount += 1
            state.lastVideoTimestamp = timestamp
        }
    }

    func appendPose(_ pose: Pose, timestamp: CMTime, imageSize: CGSize) {
        guard options.isRecordingEnabled else { return }
        queue.async { [weak self] in
            guard let self = self, let state = self.state, !state.isStopping else { return }
            guard let poseWriter = state.poseWriter else { return }
            guard let firstTimestamp = state.firstVideoTimestamp else { return }
            let tMs = PoseSerialization.timestampMs(for: timestamp, relativeTo: firstTimestamp)
            do {
                let data = try PoseSerialization.makeNDJSONLine(pose: pose, timestampMs: tMs, imageSize: imageSize)
                poseWriter.append(data)
            } catch {
                print("RecordingSessionManager pose serialization failed: \(error)")
            }
        }
    }

    func stop(completion: ((Result<URL, Error>) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self, let state = self.state else {
                completion?(.failure(RecordingError.notRecording))
                return
            }

            state.isStopping = true
            let directoryURL = state.directoryURL
            state.poseWriter?.close()
            state.poseWriter = nil

            let finalize: () -> Void = {
                self.finalizeMetadata(for: state)
                do {
                    try self.writeMetadata(for: state)
                    completion?(.success(directoryURL))
                } catch {
                    completion?(.failure(error))
                }
                self.state = nil
            }

            guard let writer = state.assetWriter, let input = state.videoInput else {
                finalize()
                return
            }

            input.markAsFinished()
            writer.finishWriting {
                self.queue.async {
                    finalize()
                }
            }
        }
    }

    func cancel() {
        queue.async { [weak self] in
            guard let self = self, let state = self.state else { return }
            state.isStopping = true
            state.poseWriter?.close()
            state.poseWriter = nil
            if let writer = state.assetWriter {
                writer.cancelWriting()
            }
            self.state = nil
            try? self.fileManager.removeItem(at: state.directoryURL)
        }
    }

    // MARK: - Helpers

    private func makeMetadata(sessionId: String,
                              cameraPosition: AVCaptureDevice.Position,
                              preset: AVCaptureSession.Preset) -> SessionMetadata {
        let device = SessionMetadata.Device(
            model: UIDevice.current.model,
            os: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        )
        let camera = SessionMetadata.Camera(
            position: cameraPosition == .front ? "front" : "back",
            preset: preset.rawValue
        )
        let video = SessionMetadata.Video(
            file: Constants.videoFilename,
            codec: Constants.videoCodec,
            size: nil,
            fps: nil
        )
        let pose = SessionMetadata.PoseInfo(
            file: Constants.poseFilename,
            jointSet: Constants.poseJointSet,
            coords: Constants.poseCoords
        )
        return SessionMetadata(
            schemaVersion: 1,
            sessionId: sessionId,
            createdAt: isoFormatter.string(from: Date()),
            device: device,
            camera: camera,
            video: video,
            pose: pose
        )
    }

    private func writeMetadata(for state: SessionState) throws {
        let url = state.directoryURL.appendingPathComponent(Constants.metadataFilename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state.metadata)
        try data.write(to: url, options: .atomic)
    }

    private func prepareAssetWriterIfNeeded(using sampleBuffer: CMSampleBuffer, state: SessionState) throws {
        guard state.assetWriter == nil else { return }
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw RecordingError.writerSetupFailed
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let videoURL = state.directoryURL.appendingPathComponent(Constants.videoFilename)
        let writer = try AVAssetWriter(outputURL: videoURL, fileType: .mp4)

        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height)
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        input.expectsMediaDataInRealTime = true

        guard writer.canAdd(input) else {
            throw RecordingError.writerSetupFailed
        }

        writer.add(input)
        state.assetWriter = writer
        state.videoInput = input
        state.videoDimensions = dimensions
        state.metadata.video.size = [Int(dimensions.width), Int(dimensions.height)]
    }

    private func finalizeMetadata(for state: SessionState) {
        defer {
            // Ensure FPS is non-negative even if duration is zero or invalid.
            if let fps = state.metadata.video.fps, !fps.isFinite {
                state.metadata.video.fps = nil
            }
        }

        if let first = state.firstVideoTimestamp, let last = state.lastVideoTimestamp, last > first {
            let delta = CMTimeSubtract(last, first)
            let seconds = CMTimeGetSeconds(delta)
            if seconds > 0 {
                let frameCount = max(Double(state.frameCount - 1), 1.0)
                state.metadata.video.fps = frameCount / seconds
            }
        }
    }

    private func makeSessionsRoot() throws -> URL {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RecordingError.directoryCreationFailed
        }
        let sessions = documents.appendingPathComponent(Constants.sessionsDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: sessions.path) {
            try fileManager.createDirectory(at: sessions, withIntermediateDirectories: true, attributes: nil)
        }
        return sessions
    }

    private static func makeSessionId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let base = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1000...9999)
        return "\(base)-\(randomSuffix)"
    }
}
