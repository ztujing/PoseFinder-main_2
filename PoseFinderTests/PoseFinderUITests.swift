import XCTest

final class PoseFinderUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testRecordingCompletionNavigation() throws {
        // ホームからメニュー選択
        let menuButton = app.buttons["メニュー選択"]
        XCTAssertTrue(menuButton.exists)
        menuButton.tap()

        // 撮影開始
        let recordButton = app.buttons["撮影を開始"]
        XCTAssertTrue(recordButton.exists)
        recordButton.tap()

        // 撮影完了（シミュレート: 実際の撮影は手動）
        // 完了後、SessionDetail へ遷移することを確認
        let sessionDetail = app.otherElements["SessionDetail"]
        XCTAssertTrue(sessionDetail.waitForExistence(timeout: 10))
    }

    func testPoseSyncPlayback() throws {
        // セッション一覧から選択
        let sessionList = app.otherElements["SessionList"]
        XCTAssertTrue(sessionList.exists)
        let sessionCell = app.cells.firstMatch
        sessionCell.tap()

        // 動画再生と Pose オーバーレイ確認
        let videoPlayer = app.otherElements["VideoPlayer"]
        XCTAssertTrue(videoPlayer.exists)

        // 再生開始（シミュレート）
        // Pose が同期表示されることを確認（視覚確認が必要）
    }
}