import Foundation

// トレーニングメニューのデータ取得インターフェース
// ローカル JSON、リモート API など、複数のデータソースに対応可能
protocol TrainingMenuDataSource: AnyObject {
    /// トレーニングメニュー一覧を取得
    func fetchTrainingMenus() async throws -> [TrainingMenu]

    /// 動画ファイルのローカル URL を取得
    /// - Parameter fileName: 動画ファイル名（例: "squat-guide.mp4"）
    /// - Returns: 動画ファイルの URL、ファイルが見つからない場合は nil
    func getVideoURL(for fileName: String) -> URL?
}
