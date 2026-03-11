import XCTest

final class PoseFinderUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        throw XCTSkip("UI tests require a dedicated UI test target with targetApplicationPath.")
    }

    func testRecordingCompletionNavigation() throws {
        launchApp(with: [UITestArg.seedSession, UITestArg.autoCompleteRecording])

        let firstMenuRow = app.otherElements["home.menu.row.0"]
        XCTAssertTrue(firstMenuRow.waitForExistence(timeout: 5))
        firstMenuRow.tap()

        let startRecordingButton = app.buttons["training.startRecording.button"]
        XCTAssertTrue(startRecordingButton.waitForExistence(timeout: 5))
        startRecordingButton.tap()

        let sessionDetailRoot = app.otherElements["session.detail.root"]
        XCTAssertTrue(sessionDetailRoot.waitForExistence(timeout: 10))
    }

    func testPoseSyncPlayback() throws {
        launchApp(with: [UITestArg.seedSession])

        let historyButton = app.buttons["home.history.button"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()

        let sessionList = app.otherElements["session.list.root"]
        XCTAssertTrue(sessionList.waitForExistence(timeout: 5))

        let seededSessionRow = app.otherElements["session.list.completeRow.\(UITestArg.seededSessionID)"]
        XCTAssertTrue(seededSessionRow.waitForExistence(timeout: 5))
        seededSessionRow.tap()

        let sessionDetailRoot = app.otherElements["session.detail.root"]
        XCTAssertTrue(sessionDetailRoot.waitForExistence(timeout: 10))

        let posePreview = app.otherElements["session.detail.posePreview"]
        XCTAssertTrue(posePreview.waitForExistence(timeout: 10))
    }

    private func launchApp(with arguments: [String]) {
        app.launchArguments = arguments
        app.launch()
    }
}

private enum UITestArg {
    static let seedSession = "-UITestSeedSession"
    static let autoCompleteRecording = "-UITestAutoCompleteRecording"
    static let seededSessionID = "ui-test-session-001"
}
