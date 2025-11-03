import Combine
import Foundation

final class TrainingMenuDetailViewModel: ObservableObject {
    @Published private(set) var menu: TrainingMenu

    init(menu: TrainingMenu) {
        self.menu = menu
    }
}
