import AVFoundation
import Foundation

final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var session: RecordingSession
    @Published private(set) var posePreview: PoseFrame?
    @Published var errorMessage: String?

    let player: AVPlayer?

    private let repository: RecordingSessionRepository

    init(session: RecordingSession, repository: RecordingSessionRepository = RecordingSessionRepository()) {        self.session = session
        self.repository = repository
        if let videoURL = session.videoURL {
            self.player = AVPlayer(url: videoURL)
        } else {
            self.player = nil
        }
        loadPosePreview()
    }

    private func loadPosePreview() {
        guard let poseURL = session.poseURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.loadFirstPoseFrame(from: poseURL)
            DispatchQueue.main.async {
                switch result {
                case .success(let frame):
                    self.posePreview = frame
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
