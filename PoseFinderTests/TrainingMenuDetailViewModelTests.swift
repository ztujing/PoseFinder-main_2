import XCTest
import AVKit
@testable import PoseFinder

final class TrainingMenuDetailViewModelTests: XCTestCase {
    func testVideoURL_fallbacksBundle() {
        let menu = TrainingMenu(id: "x", title: "X", description: "", focusPoints: [], estimatedDurationMinutes: nil, videoFileName: "bg_blue.mp4")
        let vm = TrainingMenuDetailViewModel(menu: menu, repository: TrainingMenuRepository(dataSource: MockDataSource()))
        let url = vm.videoURL()
        XCTAssertNotNil(url)
    }
}
