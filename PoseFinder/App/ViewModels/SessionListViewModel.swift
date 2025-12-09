import Foundation

final class SessionListViewModel: ObservableObject {
    @Published private(set) var sessions: [RecordingSession] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let repository: RecordingSessionRepository
    private var completionObserver: NSObjectProtocol?

    init(repository: RecordingSessionRepository = RecordingSessionRepository()) {
        self.repository = repository
        completionObserver = NotificationCenter.default.addObserver(
            forName: .recordingSessionDidComplete,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }
    
    deinit {
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refresh() {
        print("[SessionListViewModel] refresh started at \(Date())")
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.fetchSessions()
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let sessions):
                    self.sessions = sessions
                    print("[SessionListViewModel] refresh succeeded with \(sessions.count) sessions at \(Date())")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.sessions = []
                    print("[SessionListViewModel] refresh failed: \(error.localizedDescription) at \(Date())")
                }
            }
        }
    }
}
