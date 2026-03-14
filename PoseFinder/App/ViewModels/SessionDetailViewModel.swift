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
    private let poseLoadQueue = DispatchQueue(label: "SessionDetailViewModel.poseLoadQueue", qos: .userInitiated)
    private var poseFrameIndex: RecordingSessionRepository.PoseFrameIndex?
    private var poseFrameCache: [Int: PoseFrame] = [:]
    private var poseFrameCacheOrder: [Int] = []
    private var poseLoadGeneration: Int = 0
    private var requestedPoseFrameIndex: Int?
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
            let result = self.repository.loadPoseFrameIndex(from: poseURL)
            DispatchQueue.main.async {
                switch result {
                case .success(let index):
                    self.poseLoadGeneration += 1
                    self.poseFrameIndex = index
                    self.poseFrameCache.removeAll()
                    self.poseFrameCacheOrder.removeAll()
                    self.requestedPoseFrameIndex = nil
                    self.posePreview = self.loadPoseFrameSynchronously(from: index, at: 0)
                    self.updateCurrentPoseFrame(at: self.player?.currentTime() ?? .zero)
                    self.startTimeObserverIfNeeded()
                    print("[SessionDetailViewModel] pose frame index load succeeded for \(session.id) at \(Date()) count=\(index.count)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.poseFrameIndex = nil
                    self.poseFrameCache.removeAll()
                    self.poseFrameCacheOrder.removeAll()
                    self.currentPoseFrame = nil
                    print("[SessionDetailViewModel] pose frame index load failed for \(session.id): \(error.localizedDescription)")
                }
            }
        }
    }

    // --- Time Sync ---

    func startTimeObserverIfNeeded() {
        guard timeObserverToken == nil else { return }
        guard let player = player, let index = poseFrameIndex, index.count > 0 else { return }

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
        guard let index = poseFrameIndex else {
            currentPoseFrame = nil
            return
        }
        let currentMs = Int((CMTimeGetSeconds(time) * 1000.0).rounded())
        guard let poseIndex = index.closestFrameIndex(for: currentMs) else {
            currentPoseFrame = nil
            return
        }
        if let cached = poseFrameCache[poseIndex] {
            currentPoseFrame = cached
            preloadPoseFramesIfNeeded(around: poseIndex)
            return
        }

        guard requestedPoseFrameIndex != poseIndex else { return }
        requestedPoseFrameIndex = poseIndex
        let generation = poseLoadGeneration
        let activeIndex = index

        poseLoadQueue.async { [weak self] in
            guard let self else { return }
            let result = self.repository.loadPoseFrame(from: activeIndex, at: poseIndex)
            DispatchQueue.main.async {
                guard generation == self.poseLoadGeneration else { return }
                guard self.requestedPoseFrameIndex == poseIndex else { return }
                self.requestedPoseFrameIndex = nil
                if case .success(let frame) = result {
                    self.cachePoseFrame(frame, at: poseIndex)
                    self.currentPoseFrame = frame
                    self.preloadPoseFramesIfNeeded(around: poseIndex)
                }
            }
        }
    }

    private func preloadPoseFramesIfNeeded(around centerIndex: Int) {
        guard let index = poseFrameIndex else { return }
        let candidates = [centerIndex - 2, centerIndex - 1, centerIndex + 1, centerIndex + 2]
            .filter { $0 >= 0 && $0 < index.count && poseFrameCache[$0] == nil }
        guard !candidates.isEmpty else { return }
        let generation = poseLoadGeneration
        let activeIndex = index

        poseLoadQueue.async { [weak self] in
            guard let self else { return }
            let loaded: [(Int, PoseFrame)] = candidates.compactMap { candidate in
                let result = self.repository.loadPoseFrame(from: activeIndex, at: candidate)
                if case .success(let frame) = result {
                    return (candidate, frame)
                }
                return nil
            }

            guard !loaded.isEmpty else { return }
            DispatchQueue.main.async {
                guard generation == self.poseLoadGeneration else { return }
                for (candidate, frame) in loaded where self.poseFrameCache[candidate] == nil {
                    self.cachePoseFrame(frame, at: candidate)
                }
            }
        }
    }

    private func cachePoseFrame(_ frame: PoseFrame, at index: Int) {
        if poseFrameCache[index] == nil {
            poseFrameCacheOrder.append(index)
        }
        poseFrameCache[index] = frame

        let maxCacheSize = 180
        if poseFrameCacheOrder.count > maxCacheSize {
            let removeCount = poseFrameCacheOrder.count - maxCacheSize
            for _ in 0..<removeCount {
                let evicted = poseFrameCacheOrder.removeFirst()
                poseFrameCache.removeValue(forKey: evicted)
            }
        }
    }

    private func loadPoseFrameSynchronously(from index: RecordingSessionRepository.PoseFrameIndex, at position: Int) -> PoseFrame? {
        let result = repository.loadPoseFrame(from: index, at: position)
        if case .success(let frame) = result {
            cachePoseFrame(frame, at: position)
            return frame
        }
        return nil
    }
}
