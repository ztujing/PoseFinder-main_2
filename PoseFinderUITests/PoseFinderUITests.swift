import XCTest

final class PoseFinderUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testRecordingCompletionNavigation() throws {
        launchApp(with: [UITestArg.seedSession, UITestArg.openTrainingDetail, UITestArg.autoCompleteRecording])

        let startRecordingButton = element("training.startRecording.button")
        XCTAssertTrue(startRecordingButton.waitForExistence(timeout: 10))
        startRecordingButton.tap()

        let sessionDetailRoot = element("session.detail.root")
        XCTAssertTrue(sessionDetailRoot.waitForExistence(timeout: 15))
    }

    func testPoseSyncPlayback() throws {
        launchApp(with: [UITestArg.seedSession, UITestArg.openSessionList])

        let sessionList = app.collectionViews["session.list.root"].firstMatch
        XCTAssertTrue(sessionList.waitForExistence(timeout: 10))

        let seededSessionRow = app.buttons["session.list.completeRow.\(UITestArg.seededSessionID)"].firstMatch
        XCTAssertTrue(seededSessionRow.waitForExistence(timeout: 10))
        seededSessionRow.tap()

        let sessionDetailRoot = element("session.detail.root")
        XCTAssertTrue(sessionDetailRoot.waitForExistence(timeout: 15))

        let posePreview = element("session.detail.posePreview")
        XCTAssertTrue(posePreview.waitForExistence(timeout: 10))
    }

    private func launchApp(with arguments: [String]) {
        app.launchArguments = arguments
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}

private enum UITestArg {
    static let seedSession = "-UITestSeedSession"
    static let autoCompleteRecording = "-UITestAutoCompleteRecording"
    static let openSessionList = "-UITestOpenSessionList"
    static let openTrainingDetail = "-UITestOpenTrainingDetail"
    static let seededSessionID = "ui-test-session-001"
}
