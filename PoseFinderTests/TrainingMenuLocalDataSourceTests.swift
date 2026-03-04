import XCTest
@testable import PoseFinder

final class TrainingMenuLocalDataSourceTests: XCTestCase {
    var dataSource: TrainingMenuLocalDataSource!

    override func setUp() {
        super.setUp()
        dataSource = TrainingMenuLocalDataSource()
    }

    func testFetchTrainingMenus_returnsMenus() async throws {
        let menus = try await dataSource.fetchTrainingMenus()
        XCTAssertFalse(menus.isEmpty, "menus should not be empty")
        XCTAssertEqual(menus.count, 3)
        XCTAssertEqual(menus[0].id, "squat")
    }

    func testGetVideoURL_nonexistent_returnsNil() {
        let url = dataSource.getVideoURL(for: "no-such-file.mp4")
        XCTAssertNil(url)
    }
}
