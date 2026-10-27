import XCTest
final class DemoUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws { continueAfterFailure = false; app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch() }
    func dismissKeyboardIntro() { if app.buttons["Continue"].waitForExistence(timeout: 2) { app.buttons["Continue"].tap() } }
    func testMainFlowSearchValidationBackCancellationAndReset() {
        app.buttons["enter-demo"].tap(); app.buttons["send-zelle"].tap(); app.buttons["recipient-search"].tap()
        let search = app.textFields["search-field"]
        XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); dismissKeyboardIntro(); search.typeText("unknown recipient"); XCTAssertFalse(app.buttons["recipient-jordan"].exists); app.buttons["Clear search"].tap(); search.typeText("2025550146"); app.buttons["recipient-jordan"].tap()
        let amount = app.textFields["amount-field"]; XCTAssertTrue(amount.waitForExistence(timeout: 5))
        app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.alerts["Check your demo payment"].waitForExistence(timeout: 3)); app.alerts.buttons["OK"].tap()
        app.swipeDown(); amount.tap(); dismissKeyboardIntro(); amount.typeText("24.50")
        let message = app.textFields["message-field"]; message.tap(); dismissKeyboardIntro(); message.typeText("Demo lunch"); app.toolbars.buttons["Done"].tap()
        app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.buttons["send-now"].waitForExistence(timeout: 3)); XCTAssertTrue(app.staticTexts["Demo lunch"].exists)
        app.buttons["Back"].tap(); XCTAssertEqual(amount.value as? String, "24.50")
        app.buttons["Cancel"].tap(); app.buttons["Keep editing"].tap(); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].tap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertEqual(app.staticTexts["confirmation-amount"].label, "$24.50")
        app.buttons["confirmation-done"].tap(); app.buttons["See activity"].tap(); XCTAssertTrue(app.staticTexts["Demo lunch"].waitForExistence(timeout: 3)); app.buttons["Close"].tap()
        app.buttons["tab-More"].tap(); app.buttons["reset-demo"].tap(); app.buttons.matching(identifier: "Reset demo").firstMatch.tap()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 3))
    }
    func testMessageLimitAndDiscard() {
        app.buttons["enter-demo"].tap(); app.buttons["send-zelle"].tap(); app.buttons["recent-jordan"].tap()
        let message = app.textFields["message-field"]; message.tap(); dismissKeyboardIntro(); message.typeText(String(repeating: "x", count: 145)); XCTAssertEqual((message.value as? String)?.count, 140)
        app.toolbars.buttons["Done"].tap(); app.buttons["Cancel"].tap(); app.buttons["Discard payment"].tap(); XCTAssertTrue(app.buttons["recipient-search"].waitForExistence(timeout: 3))
    }
    func testScheduledAccountFrequencyAndSingleSubmission() {
        app.terminate(); app.launchArguments = ["--ui-testing", "--demo-screen", "amount"]; app.launch()
        app.swipeUp(); app.buttons["date-picker"].tap(); app.buttons["In 2 days"].tap(); app.buttons["Use selected date"].tap()
        app.buttons["account-picker"].tap(); app.buttons.containing(.staticText, identifier: "DEMO SAVINGS (...8391)").firstMatch.tap()
        app.switches["repeat-toggle"].tap(); app.buttons["Monthly"].tap()
        app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.staticTexts["Nov 14, 2026"].exists); XCTAssertTrue(app.staticTexts["Monthly"].exists); XCTAssertTrue(app.staticTexts["DEMO SAVINGS (...8391)"].exists)
        app.buttons["Back"].tap(); XCTAssertTrue(app.buttons["date-picker"].label.contains("Nov 14, 2026"))
        app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].doubleTap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains("Nov 14, 2026"))
        app.buttons["confirmation-done"].tap(); app.buttons["See activity"].tap()
        XCTAssertEqual(app.staticTexts["Jordan Ellis"].count, 1); XCTAssertTrue(app.staticTexts["Scheduled • Nov 14, 2026"].exists)
    }

}
