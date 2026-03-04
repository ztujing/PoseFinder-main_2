import Combine
import Foundation

final class TrainingMenuDetailViewModel: ObservableObject {
    @Published private(set) var menu: TrainingMenu

    private let repository: TrainingMenuRepository

    init(menu: TrainingMenu, repository: TrainingMenuRepository = TrainingMenuRepository()) {
        self.menu = menu
        self.repository = repository
    }

    func videoURL() -> URL? {
        guard let fileName = menu.videoFileName else { return nil }
        if let url = repository.getVideoURL(for: fileName) {
            return url
        }

        if let bundleVideoURL = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "videos") {
            return bundleVideoURL
        }

        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}
