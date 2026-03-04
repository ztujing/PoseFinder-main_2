import Foundation

// ローカル JSON ファイルからトレーニングメニューを読み込む実装
final class TrainingMenuLocalDataSource: TrainingMenuDataSource {
    // MARK: - Internal Structure

    private struct TrainingMenuContainer: Codable {
        let trainings: [TrainingMenu]
    }

    // MARK: - Constants

    private let jsonFileName = "training-menus"
    private let documentsDirectoryName = "PoseFinderTrainingMenus"
    private let videosDirectoryName = "videos"

    // MARK: - TrainingMenuDataSource

    func fetchTrainingMenus() async throws -> [TrainingMenu] {
        let fileManager = FileManager.default

        // まず Documents にコピー済みのファイルを探す
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let candidate = documentsURL
                .appendingPathComponent(documentsDirectoryName)
                .appendingPathComponent("training-menus.json")
            if fileManager.fileExists(atPath: candidate.path) {
                let data = try Data(contentsOf: candidate)
                let container = try JSONDecoder().decode(TrainingMenuContainer.self, from: data)
                return container.trainings
            }
        }

        // 次にバンドル内のリソースを探す
        if let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(TrainingMenuContainer.self, from: data)
            return container.trainings
        }

        throw TrainingMenuDataSourceError.resourceNotFound(jsonFileName)
    }

    func getVideoURL(for fileName: String) -> URL? {
        let fileManager = FileManager.default

        // Documents/PoseFinderTrainingMenus/videos/ から探索
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let videosURL = documentsURL
            .appendingPathComponent(documentsDirectoryName)
            .appendingPathComponent(videosDirectoryName)
            .appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: videosURL.path) else {
            return nil
        }

        return videosURL
    }
}

// MARK: - Error

enum TrainingMenuDataSourceError: Error, LocalizedError {
    case resourceNotFound(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .decodingError(let reason):
            return "Failed to decode: \(reason)"
        }
    }
}
