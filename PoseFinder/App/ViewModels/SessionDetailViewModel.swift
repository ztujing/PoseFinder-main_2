import AVFoundation
import Foundation

final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var session: RecordingSession
    @Published private(set) var posePreview: PoseFrame?
    @Published var errorMessage: String?
    @Published var player: AVPlayer?
    @Published var isReloading: Bool = false

    private let repository: RecordingSessionRepository

    init(session: RecordingSession, repository: RecordingSessionRepository = RecordingSessionRepository()) {
        self.session = session
        self.repository = repository
        if let videoURL = session.videoURL {
            self.player = AVPlayer(url: videoURL)
        } else {
            self.player = nil
        }
        loadPosePreview(for: session)
        reloadSession()
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
                    }
                    self.loadPosePreview(for: refreshed)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("[SessionDetailViewModel] reload failed for \(self.session.id): \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadPosePreview(for session: RecordingSession) {
        guard let poseURL = session.poseURL else {
            print("[SessionDetailViewModel] pose URL missing for session \(session.id)")
            return
        }
        print("[SessionDetailViewModel] pose preview load started for \(session.id) at \(Date())")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.loadFirstPoseFrame(from: poseURL)
            DispatchQueue.main.async {
                switch result {
                case .success(let frame):
                    self.posePreview = frame
                    print("[SessionDetailViewModel] pose preview load succeeded for \(session.id) at \(Date())")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("[SessionDetailViewModel] pose preview load failed for \(session.id): \(error.localizedDescription)")
                }
            }
        }
    }
}
