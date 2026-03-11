import XCTest
@testable import PoseFinder

final class MockDataSource: TrainingMenuDataSource {
    var menusToReturn: [TrainingMenu] = []
    var urlToReturn: URL?
    var shouldThrow = false

    func fetchTrainingMenus() async throws -> [TrainingMenu] {
        if shouldThrow { throw NSError(domain: "test", code: 1)
        }
        return menusToReturn
    }

    func getVideoURL(for fileName: String) -> URL? {
        return urlToReturn
    }
}

final class TrainingMenuRepositoryTests: XCTestCase {
    func testGetTrainingMenus_cachesValue() async throws {
        let mock = MockDataSource()
        mock.menusToReturn = [TrainingMenu(id: "a", title: "A", description: "", focusPoints: [], estimatedDurationMinutes: nil, videoFileName: nil)]
        let repo = TrainingMenuRepository(dataSource: mock)

        let first = try await repo.getTrainingMenus()
        XCTAssertEqual(first.count, 1)
        mock.menusToReturn = []
        let second = try await repo.getTrainingMenus()
        XCTAssertEqual(second.count, 1, "should return cached value even if datasource changed")
    }

    func testGetTrainingMenus_propagatesError() async {
        let mock = MockDataSource()
        mock.shouldThrow = true
        let repo = TrainingMenuRepository(dataSource: mock)

        do {
            _ = try await repo.getTrainingMenus()
            XCTFail("Expected getTrainingMenus to throw")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
