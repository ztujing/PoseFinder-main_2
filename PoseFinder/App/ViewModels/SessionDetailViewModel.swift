// 目的: セッション詳細の再生/表示状態を管理し、動画とPoseの同期表示を行う。
// 入出力: `RecordingSession` / `AVPlayer` の状態とPoseフレームの配信。
// 依存: RecordingSessionRepository, AVFoundation。
// 副作用: ファイルI/O、タイムオブザーバの登録/解除。

import AVFoundation
import Foundation

final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var session: RecordingSession
    @Published private(set) var posePreview: PoseFrame?
    @Published private(set) var currentPoseFrame: PoseFrame?
    @Published var errorMessage: String?
    @Published var player: AVPlayer?
    @Published var isReloading: Bool = false

    private let repository: RecordingSessionRepository
    private var poseFrames: [PoseFrame] = []
    private var timeObserverToken: Any?

    init(session: RecordingSession, repository: RecordingSessionRepository = RecordingSessionRepository()) {
        self.session = session
        self.repository = repository
        if let videoURL = session.videoURL {
            self.player = AVPlayer(url: videoURL)
        } else {
            self.player = nil
        }
        loadPoseFrames(for: session)
        reloadSession()
    }

    deinit {
        stopTimeObserver()
    }

    func reloadSessionWithDelay(delay: TimeInterval = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            print("[SessionDetailViewModel] delayed reload firing for \(self.session.id) at \(Date())")
            self.reloadSession()
        }
    }

    func reloadSession() {
        guard !isReloading else {
            print("[SessionDetailViewModel] reload skipped because another reload is in progress.")
            return
        }
        isReloading = true
        print("[SessionDetailViewModel] reload started for \(session.id) at \(Date())")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.reloadSession(at: self.session.directoryURL)
            DispatchQueue.main.async {
                self.isReloading = false
                switch result {
                case .success(let refreshed):
                    guard refreshed.video != nil || refreshed.pose != nil else {
                        print("[SessionDetailViewModel] reload returned incomplete data for \(refreshed.id), keeping existing values.")
                        return
                    }
                    print("[SessionDetailViewModel] reload succeeded for \(refreshed.id) at \(Date()) video:\(refreshed.video != nil) pose:\(refreshed.pose != nil)")
                    let oldPoseURL = self.session.poseURL
                    self.session = refreshed
                    if oldPoseURL != refreshed.poseURL {
                        self.posePreview = nil
                        self.currentPoseFrame = nil
                    }
                    self.loadPoseFrames(for: refreshed)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("[SessionDetailViewModel] reload failed for \(self.session.id): \(error.localizedDescription)")
                }
            }
        }
    }

    // --- Pose Loading ---

    private func loadPoseFrames(for session: RecordingSession) {
        guard let poseURL = session.poseURL else {
            print("[SessionDetailViewModel] pose URL missing for session \(session.id)")
            return
        }
        print("[SessionDetailViewModel] pose frames load started for \(session.id) at \(Date())")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.loadAllPoseFrames(from: poseURL)
            DispatchQueue.main.async {
                switch result {
                case .success(let frames):
                    self.poseFrames = frames
                    self.posePreview = frames.first
                    self.updateCurrentPoseFrame(at: self.player?.currentTime() ?? .zero)
                    self.startTimeObserverIfNeeded()
                    print("[SessionDetailViewModel] pose frames load succeeded for \(session.id) at \(Date()) count=\(frames.count)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.poseFrames = []
                    self.currentPoseFrame = nil
                    print("[SessionDetailViewModel] pose frames load failed for \(session.id): \(error.localizedDescription)")
                }
            }
        }
    }

    // --- Time Sync ---

    func startTimeObserverIfNeeded() {
        guard timeObserverToken == nil else { return }
        guard let player = player, !poseFrames.isEmpty else { return }

        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateCurrentPoseFrame(at: time)
        }
    }

    func stopTimeObserver() {
        guard let token = timeObserverToken, let player = player else { return }
        player.removeTimeObserver(token)
        timeObserverToken = nil
    }

    private func updateCurrentPoseFrame(at time: CMTime) {
        guard !poseFrames.isEmpty else {
            currentPoseFrame = nil
            return
        }
        let currentMs = Int((CMTimeGetSeconds(time) * 1000.0).rounded())
        if let index = closestPoseFrameIndex(for: currentMs) {
            currentPoseFrame = poseFrames[index]
        }
    }

    private func closestPoseFrameIndex(for timestampMs: Int) -> Int? {
        guard !poseFrames.isEmpty else { return nil }
        if timestampMs <= poseFrames[0].timestampMs { return 0 }
        if timestampMs >= poseFrames[poseFrames.count - 1].timestampMs { return poseFrames.count - 1 }

        var low = 0
        var high = poseFrames.count - 1
        // 二分探索で最も近いフレーム候補を特定する。
        while low <= high {
            let mid = (low + high) / 2
            let midTs = poseFrames[mid].timestampMs
            if midTs == timestampMs {
                return mid
            } else if midTs < timestampMs {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        let lowerIndex = max(high, 0)
        let upperIndex = min(low, poseFrames.count - 1)
        let lowerDelta = abs(poseFrames[lowerIndex].timestampMs - timestampMs)
        let upperDelta = abs(poseFrames[upperIndex].timestampMs - timestampMs)
        return lowerDelta <= upperDelta ? lowerIndex : upperIndex
    }
}
