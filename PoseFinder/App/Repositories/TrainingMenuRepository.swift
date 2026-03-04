import Foundation

// トレーニングメニュー取得ロジックを統括する Repository
// 依存性注入により DataSource を切り替え可能（ローカル ↔ リモート）
final class TrainingMenuRepository {
    // MARK: - Properties

    private let dataSource: TrainingMenuDataSource
    private var cachedMenus: [TrainingMenu]?

    // MARK: - Init

    init(dataSource: TrainingMenuDataSource) {
        self.dataSource = dataSource
    }

    // 便利イニシャライザ（デフォルトはローカルデータソース）
    convenience init() {
        self.init(dataSource: TrainingMenuLocalDataSource())
    }

    // MARK: - Public Methods

    /// トレーニングメニュー一覧を取得
    /// キャッシュがあればキャッシュから返す
    func getTrainingMenus() async throws -> [TrainingMenu] {
        // キャッシュが存在すればそれを返す
        if let cached = cachedMenus {
            return cached
        }

        // キャッシュなければデータソースから取得
        let menus = try await dataSource.fetchTrainingMenus()
        self.cachedMenus = menus
        return menus
    }

    /// キャッシュをクリア
    func clearCache() {
        cachedMenus = nil
    }

    /// 動画ファイルの URL を取得
    func getVideoURL(for fileName: String) -> URL? {
        dataSource.getVideoURL(for: fileName)
    }
}
