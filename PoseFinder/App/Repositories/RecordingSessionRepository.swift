// 目的: セッションメタ/動画/Poseデータを読み込み、UI向けモデルへ変換する。
// 入出力: Documents配下のセッションファイル読み込みと `RecordingSession` / `PoseFrame` 生成。
// 依存: FileManager, JSONDecoder, PoseSerialization。
// 副作用: ファイルI/O。

import CoreGraphics
import Foundation

struct RecordingSessionRepository {
    struct PoseFrameIndex {
        fileprivate struct Entry {
            let timestampMs: Int
            let offset: UInt64
            let length: Int
        }

        fileprivate let fileURL: URL
        fileprivate let entries: [Entry]

        var count: Int {
            entries.count
        }

        func closestFrameIndex(for timestampMs: Int) -> Int? {
            guard !entries.isEmpty else { return nil }
            if timestampMs <= entries[0].timestampMs { return 0 }
            if timestampMs >= entries[entries.count - 1].timestampMs { return entries.count - 1 }

            var low = 0
            var high = entries.count - 1
            // 二分探索で最も近いフレーム候補を特定する。
            while low <= high {
                let mid = (low + high) / 2
                let midTs = entries[mid].timestampMs
                if midTs == timestampMs {
                    return mid
                } else if midTs < timestampMs {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }

            let lowerIndex = max(high, 0)
            let upperIndex = min(low, entries.count - 1)
            let lowerDelta = abs(entries[lowerIndex].timestampMs - timestampMs)
            let upperDelta = abs(entries[upperIndex].timestampMs - timestampMs)
            return lowerDelta <= upperDelta ? lowerIndex : upperIndex
        }
    }

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

    func reloadSession(at directoryURL: URL) -> Result<RecordingSession, Error> {
        do {
            guard let session = try loadSession(at: directoryURL) else {
                throw RepositoryError.metadataMissing(directoryURL.appendingPathComponent("session.json"))
            }
            return .success(session)
        } catch {
            return .failure(error)
        }
    }

    func loadFirstPoseFrame(from url: URL) -> Result<PoseFrame, Error> {
        do {
            guard fileManager.fileExists(atPath: url.path) else {
                throw RepositoryError.fileNotFound(url)
            }

            if let size = fileSize(at: url), size == 0 {
                throw RepositoryError.emptyPoseFile
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            let newline = Data([0x0a])
            var buffer = Data()

            // NDJSONをチャンクで読み込み、改行区切りでフレームを復元する。
            while true {
                let chunk = handle.readData(ofLength: 4096)
                if chunk.isEmpty, buffer.isEmpty { break }
                buffer.append(chunk)

                // 行単位で復元し、パースできるフレームのみ採用する。
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

    func loadAllPoseFrames(from url: URL) -> Result<[PoseFrame], Error> {
        do {
            guard fileManager.fileExists(atPath: url.path) else {
                throw RepositoryError.fileNotFound(url)
            }

            if let size = fileSize(at: url), size == 0 {
                throw RepositoryError.emptyPoseFile
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            let newline = Data([0x0a])
            var buffer = Data()
            var frames: [PoseFrame] = []

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
                        frames.append(frame)
                    } catch {
                        // 無効行はスキップして継続
                        continue
                    }
                }

                if chunk.isEmpty { break }
            }

            if frames.isEmpty {
                throw RepositoryError.poseFrameNotFound
            }

            return .success(frames.sorted(by: { $0.timestampMs < $1.timestampMs }))
        } catch {
            return .failure(error)
        }
    }

    func loadPoseFrameIndex(from url: URL) -> Result<PoseFrameIndex, Error> {
        do {
            guard fileManager.fileExists(atPath: url.path) else {
                throw RepositoryError.fileNotFound(url)
            }

            if let size = fileSize(at: url), size == 0 {
                throw RepositoryError.emptyPoseFile
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            let newline = Data([0x0a])
            var buffer = Data()
            var lineStartOffset: UInt64 = 0
            var entries: [PoseFrameIndex.Entry] = []

            func appendEntryIfPossible(lineData: Data, offset: UInt64) {
                guard let cleaned = cleanedLineData(from: lineData), !cleaned.isEmpty else {
                    return
                }
                guard let frame = try? decodePoseFrame(from: cleaned) else {
                    return
                }
                entries.append(.init(timestampMs: frame.timestampMs, offset: offset, length: lineData.count))
            }

            while true {
                let chunk = handle.readData(ofLength: 4096)
                if chunk.isEmpty, buffer.isEmpty { break }
                buffer.append(chunk)

                while let range = buffer.firstRange(of: newline) {
                    let lineData = buffer.subdata(in: 0..<range.lowerBound)
                    appendEntryIfPossible(lineData: lineData, offset: lineStartOffset)
                    lineStartOffset += UInt64(range.upperBound)
                    buffer.removeSubrange(0..<range.upperBound)
                }

                if chunk.isEmpty {
                    if !buffer.isEmpty {
                        appendEntryIfPossible(lineData: buffer, offset: lineStartOffset)
                        lineStartOffset += UInt64(buffer.count)
                        buffer.removeAll()
                    }
                    break
                }
            }

            if entries.isEmpty {
                throw RepositoryError.poseFrameNotFound
            }

            return .success(
                PoseFrameIndex(
                    fileURL: url,
                    entries: entries.sorted(by: { $0.timestampMs < $1.timestampMs })
                )
            )
        } catch {
            return .failure(error)
        }
    }

    func loadPoseFrame(from index: PoseFrameIndex, at position: Int) -> Result<PoseFrame, Error> {
        do {
            guard position >= 0, position < index.entries.count else {
                throw RepositoryError.poseFrameNotFound
            }
            let entry = index.entries[position]

            let handle = try FileHandle(forReadingFrom: index.fileURL)
            defer {
                try? handle.close()
            }
            try handle.seek(toOffset: entry.offset)
            let rawData = handle.readData(ofLength: entry.length)
            guard let cleaned = cleanedLineData(from: rawData), !cleaned.isEmpty else {
                throw RepositoryError.poseFrameNotFound
            }
            return .success(try decodePoseFrame(from: cleaned))
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
        case emptyPoseFile
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
        case .emptyPoseFile:
            return "Pose データが記録されませんでした（録画が短すぎた可能性があります）。"
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

        let incompleteMarkerURL = directoryURL.appendingPathComponent(RecordingSession.incompleteMarkerFilename)
        let hasIncompleteMarker = fileManager.fileExists(atPath: incompleteMarkerURL.path)
        
        let videoSize = fileSize(at: videoURL)
        let videoExists = fileManager.fileExists(atPath: videoURL.path)

        let poseSize = fileSize(at: poseURL)
        let poseExists = fileManager.fileExists(atPath: poseURL.path)
        

        print("[Repository] directoryURL = \(directoryURL.path)")
        print("[Repository] metadataURL  = \(metadataURL.path)")
        print("[Repository] video path   = \(videoURL.path) exists=\(videoExists) size=\(String(describing: videoSize))")
        print("[Repository] pose path    = \(poseURL.path) exists=\(poseExists) size=\(String(describing: poseSize))")
        print("[Repository] incomplete marker = \(hasIncompleteMarker) (\(directoryURL.appendingPathComponent(RecordingSession.incompleteMarkerFilename).path))")
        print("[Repository] metadata video.file = \(metadata.video.file)")
        print("[Repository] metadata pose.file  = \(metadata.pose.file)")

        let videoInfo: RecordingSession.VideoInfo? = videoExists ?
            RecordingSession.VideoInfo(
                fileName: metadata.video.file,
                codec: metadata.video.codec,
                size: metadata.video.size.flatMap { array -> CGSize? in
                    guard array.count == 2 else { return nil }
                    return CGSize(width: array[0], height: array[1])
                },
                fps: metadata.video.fps,
                url: videoURL,
                fileSizeBytes: videoSize
            ) : nil
        
        let poseInfo: RecordingSession.PoseInfo? = poseExists ?
            RecordingSession.PoseInfo(
                fileName: metadata.pose.file,
                jointSet: metadata.pose.jointSet,
                coords: metadata.pose.coords,
                url: poseURL,
                fileSizeBytes: poseSize
            ) : nil

        return RecordingSession(
            id: metadata.sessionId,
            createdAt: createdAt,
            directoryURL: directoryURL,
            device: .init(model: metadata.device.model, os: metadata.device.os),
            camera: .init(position: metadata.camera.position, preset: metadata.camera.preset),
            video: videoInfo,
            pose: poseInfo,
            hasIncompleteMarker: hasIncompleteMarker
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

        // 互換性対応:
        // 旧データで座標が二重に正規化されている場合、値が極端に小さくなり左上に縮んで見える。
        // jointsの最大値が十分小さい場合は二重正規化として補正する。
        let maxX = payload.joints.values.map(\.x).max() ?? 0
        let maxY = payload.joints.values.map(\.y).max() ?? 0
        let isDoubleNormalized = width > 50 && height > 50 && maxX <= 0.02 && maxY <= 0.02
        let scaleX = isDoubleNormalized ? (Double(width) * Double(width)) : Double(width)
        let scaleY = isDoubleNormalized ? (Double(height) * Double(height)) : Double(height)

        var pose = Pose()
        for (key, jointPayload) in payload.joints {
            guard let jointName = JointNameMapper.jointName(for: key) else { continue }
            var joint = pose[jointName]
            joint.position = CGPoint(
                x: CGFloat(jointPayload.x * scaleX),
                y: CGFloat(jointPayload.y * scaleY)
            )
            joint.confidence = jointPayload.c
            joint.score = jointPayload.s ?? jointPayload.c
            joint.isValid = jointPayload.c > 0
            pose[jointName] = joint
        }
        pose.confidence = payload.confidence ?? payload.score
        pose.score = payload.score > 0 ? payload.score : pose.confidence

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
