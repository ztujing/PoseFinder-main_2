import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var menus: [TrainingMenu]

    init(menus: [TrainingMenu] = TrainingMenu.sampleData) {
        self.menus = menus
    }
}
