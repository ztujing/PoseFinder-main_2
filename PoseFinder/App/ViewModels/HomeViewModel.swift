import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var menus: [TrainingMenu] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: TrainingMenuRepository

    init(repository: TrainingMenuRepository = TrainingMenuRepository()) {
        self.repository = repository
        loadMenus()
    }

    // MARK: - Private Methods

    private func loadMenus() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedMenus = try await repository.getTrainingMenus()
                await MainActor.run {
                    self.menus = fetchedMenus
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "トレーニングメニューの読み込みに失敗しました"
                    self.isLoading = false
                }
            }
        }
    }
}
