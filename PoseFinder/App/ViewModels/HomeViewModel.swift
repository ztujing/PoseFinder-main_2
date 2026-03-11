import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var menus: [TrainingMenu] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: TrainingMenuRepository

    init(repository: TrainingMenuRepository = TrainingMenuRepository()) {
        self.repository = repository
        seedMenusForUITestIfNeeded()
        loadMenus()
    }

    // MARK: - Private Methods

    private func seedMenusForUITestIfNeeded() {
        guard UITestSupport.shouldSeedSession else { return }

        menus = [
            TrainingMenu(
                id: "ui-test-training-menu-001",
                title: "UI Test Training",
                description: "UIテスト用の一時メニューです。",
                focusPoints: ["フォームを安定させる"],
                estimatedDurationMinutes: 1,
                videoFileName: nil
            )
        ]
    }

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
