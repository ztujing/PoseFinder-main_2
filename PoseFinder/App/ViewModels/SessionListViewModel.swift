import Foundation

final class SessionListViewModel: ObservableObject {
    @Published private(set) var sessions: [RecordingSession] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let repository: RecordingSessionRepository

    init(repository: RecordingSessionRepository = RecordingSessionRepository()) {
        self.repository = repository
    }

    func refresh() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.repository.fetchSessions()
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let sessions):
                    self.sessions = sessions
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.sessions = []
                }
            }
        }
    }
}
