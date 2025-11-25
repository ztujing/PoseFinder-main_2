import CoreGraphics
import Foundation

struct RecordingSessionRepository {
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let isoFormatter: ISO8601DateFormatter

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.isoFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
        self.decoder = JSONDecoder()
    }

    func fetchSessions() -> Result<[RecordingSession], Error> {
        do {
            let sessions = try loadSessions()
            return .success(sessions.sorted(by: { $0.createdAt > $1.createdAt }))
        } catch {
            return .failure(error)
        }
    }

    func loadFirstPoseFrame(from url: URL) -> Result<PoseFrame, Error> {
        do {
            guard fileManager.fileExists(atPath: url.path) else {
                throw RepositoryError.fileNotFound(url)
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            let newline = Data([0x0a])
            var buffer = Data()

            while true {
                let chunk = handle.readData(ofLength: 4096)
                if chunk.isEmpty, buffer.isEmpty { break }
                buffer.append(chunk)

                while let range = buffer.firstRange(of: newline) {
                    let lineData = buffer.subdata(in: 0..<range.lowerBound)
                    buffer.removeSubrange(0..<range.upperBound)

                    guard let cleaned = cleanedLineData(from: lineData), !cleaned.isEmpty else {
                        continue
                    }

                    do {
                        let frame = try decodePoseFrame(from: cleaned)
                        return .success(frame)
                    } catch {
                        // 続く行に有効なJSONがある場合があるため読み取りを継続
                        continue
                    }
                }

                if chunk.isEmpty { break }
            }

            throw RepositoryError.poseFrameNotFound
        } catch {
            return .failure(error)
        }
    }
}

extension RecordingSessionRepository {
    enum RepositoryError: Error {
        case documentsDirectoryUnavailable
        case metadataMissing(URL)
        case malformedMetadata(URL)
        case fileNotFound(URL)
        case poseFrameNotFound
    }
}

extension RecordingSessionRepository.RepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            return "ドキュメントディレクトリへアクセスできませんでした。"
        case .metadataMissing(let url):
            return "セッションメタ情報が見つかりません: \(url.lastPathComponent)"
        case .malformedMetadata(let url):
            return "セッションメタ情報の読み込みに失敗しました: \(url.lastPathComponent)"
        case .fileNotFound(let url):
            return "必要なファイルが見つかりません: \(url.lastPathComponent)"
        case .poseFrameNotFound:
            return "Pose データの先頭フレームを読み込めませんでした。"
        }
    }
}

// MARK: - Private helpers

private extension RecordingSessionRepository {
    struct SessionMetadata: Codable {
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
            let size: [Int]?
            let fps: Double?
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
        let video: Video
        let pose: PoseInfo
    }

    func makeSessionsDirectory() throws -> URL {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RepositoryError.documentsDirectoryUnavailable
        }
        return documents.appendingPathComponent("Sessions", isDirectory: true)
    }

    func loadSessions() throws -> [RecordingSession] {
        let sessionsDirectory = try makeSessionsDirectory()
        guard fileManager.fileExists(atPath: sessionsDirectory.path) else {
            return []
        }

        let contents = try fileManager.contentsOfDirectory(
            at: sessionsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var sessions: [RecordingSession] = []
        for url in contents {
            guard try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { continue }
            do {
                if let session = try loadSession(at: url) {
                    sessions.append(session)
                }
            } catch {
                #if DEBUG
                print("RecordingSessionRepository skipped directory \(url.lastPathComponent): \(error)")
                #endif
                continue
            }
        }
        return sessions
    }

    func loadSession(at directoryURL: URL) throws -> RecordingSession? {
        let metadataURL = directoryURL.appendingPathComponent("session.json")
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            throw RepositoryError.metadataMissing(metadataURL)
        }

        let data = try Data(contentsOf: metadataURL)
        let metadata: SessionMetadata
        do {
            metadata = try decoder.decode(SessionMetadata.self, from: data)
        } catch {
            throw RepositoryError.malformedMetadata(metadataURL)
        }

        let createdAt = isoFormatter.date(from: metadata.createdAt) ?? Date()
        let videoURL = directoryURL.appendingPathComponent(metadata.video.file)
        let poseURL = directoryURL.appendingPathComponent(metadata.pose.file)

        let videoInfo: RecordingSession.VideoInfo? = fileManager.fileExists(atPath: videoURL.path) ?
            RecordingSession.VideoInfo(
                fileName: metadata.video.file,
                codec: metadata.video.codec,
                size: metadata.video.size.flatMap { array -> CGSize? in
                    guard array.count == 2 else { return nil }
                    return CGSize(width: array[0], height: array[1])
                },
                fps: metadata.video.fps,
                url: videoURL,
                fileSizeBytes: fileSize(at: videoURL)
            ) : nil

        let poseInfo: RecordingSession.PoseInfo? = fileManager.fileExists(atPath: poseURL.path) ?
            RecordingSession.PoseInfo(
                fileName: metadata.pose.file,
                jointSet: metadata.pose.jointSet,
                coords: metadata.pose.coords,
                url: poseURL,
                fileSizeBytes: fileSize(at: poseURL)
            ) : nil

        return RecordingSession(
            id: metadata.sessionId,
            createdAt: createdAt,
            directoryURL: directoryURL,
            device: .init(model: metadata.device.model, os: metadata.device.os),
            camera: .init(position: metadata.camera.position, preset: metadata.camera.preset),
            video: videoInfo,
            pose: poseInfo
        )
    }

    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else {
            return nil
        }
        return size.int64Value
    }

    func decodePoseFrame(from data: Data) throws -> PoseFrame {
        let payload = try JSONDecoder().decode(PoseSerialization.FramePayload.self, from: data)

        let sizeArray = payload.imgSize
        let width = sizeArray.first ?? 0
        let height = sizeArray.dropFirst().first ?? 0
        let imageSize = CGSize(width: width, height: height)

        var pose = Pose()
        for (key, jointPayload) in payload.joints {
            guard let jointName = JointNameMapper.jointName(for: key) else { continue }
            var joint = pose[jointName]
            joint.position = CGPoint(
                x: CGFloat(jointPayload.x) * CGFloat(imageSize.width),
                y: CGFloat(jointPayload.y) * CGFloat(imageSize.height)
            )
            joint.confidence = jointPayload.c
            joint.score = jointPayload.c
            joint.isValid = jointPayload.c > 0
            pose[jointName] = joint
        }
        pose.confidence = payload.score
        pose.score = payload.score

        return PoseFrame(
            timestampMs: payload.tMs,
            imageSize: imageSize,
            pose: pose
        )
    }

    func cleanedLineData(from lineData: Data) -> Data? {
        var data = lineData
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            data.removeFirst(3)
        }
        guard let line = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !line.isEmpty else {
            return nil
        }

        return line.data(using: .utf8)
    }
}

private enum JointNameMapper {
    static func jointName(for key: String) -> Joint.Name? {
        switch key {
        case "nose": return .nose
        case "leftEye": return .leftEye
        case "rightEye": return .rightEye
        case "leftEar": return .leftEar
        case "rightEar": return .rightEar
        case "leftShoulder": return .leftShoulder
        case "rightShoulder": return .rightShoulder
        case "leftElbow": return .leftElbow
        case "rightElbow": return .rightElbow
        case "leftWrist": return .leftWrist
        case "rightWrist": return .rightWrist
        case "leftHip": return .leftHip
        case "rightHip": return .rightHip
        case "leftKnee": return .leftKnee
        case "rightKnee": return .rightKnee
        case "leftAnkle": return .leftAnkle
        case "rightAnkle": return .rightAnkle
        default: return nil
        }
    }
}
