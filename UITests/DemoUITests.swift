import XCTest

final class DemoUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
    }
    func dismissKeyboardIntro() {
        let intro = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Speed up your typing")).firstMatch
        if intro.waitForExistence(timeout: 1) {
            app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Continue", "enter-demo")).firstMatch.tap()
        }
    }
    func onboard() {
        let name = app.textFields["first-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); dismissKeyboardIntro(); name.typeText("Avery")
        app.buttons["enter-demo"].tap(); XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5))
    }
    func keyboardDone() { app.buttons.matching(identifier: "keyboard-done").firstMatch.tap() }
    func enterJordan() { app.buttons["send-zelle"].tap(); app.buttons["recent-jordan"].tap() }

    func testFirstNameMigrationAndPersistence() {
        app.terminate()
        let suite = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--persistent-suite", suite, "--seed-legacy"]; app.launch()
        XCTAssertTrue(app.textFields["first-name"].waitForExistence(timeout: 5))
        app.buttons["enter-demo"].tap(); XCTAssertTrue(app.staticTexts["onboarding-error"].exists)
        let name = app.textFields["first-name"]; name.tap(); dismissKeyboardIntro(); name.typeText("  Avery  "); app.buttons["enter-demo"].tap()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["AVERY CHECKING (..5020)"].exists); XCTAssertTrue(app.staticTexts["AVERY SAVINGS (..5020)"].exists)
        app.buttons["tab-More"].tap(); app.buttons["Simulated activity"].tap(); XCTAssertTrue(app.staticTexts["$12.50"].waitForExistence(timeout: 5)); app.buttons["Close"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5)); XCTAssertFalse(app.textFields["first-name"].exists)
        app.buttons["send-zelle"].tap(); app.buttons["recipient-search"].tap()
        let search = app.textFields["search-field"]; XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); dismissKeyboardIntro(); search.typeText("Jamie Vale")
        XCTAssertTrue(app.buttons["recipient-legacy-local"].waitForExistence(timeout: 5))
    }
    func testMainFlowSearchInlineValidationBackCancellationActivityAndReset() {
        onboard(); app.buttons["send-zelle"].tap(); app.buttons["recipient-search"].tap()
        let search = app.textFields["search-field"]; XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); dismissKeyboardIntro()
        search.typeText("unknown recipient"); XCTAssertFalse(app.buttons["recipient-jordan"].exists)
        app.buttons["Clear search"].tap(); search.typeText("2025550146"); app.buttons["recipient-jordan"].tap()
        let amount = app.textFields["amount-field"]; XCTAssertTrue(amount.waitForExistence(timeout: 5)); XCTAssertEqual(amount.value as? String, "$0.00")
        XCTAssertFalse(app.staticTexts["amount-error"].exists)
        app.swipeUp(); app.buttons["review-send"].tap(); XCTAssertTrue(app.staticTexts["amount-error"].waitForExistence(timeout: 5)); XCTAssertFalse(app.alerts["Check your demo payment"].exists)
        amount.tap(); dismissKeyboardIntro(); amount.typeText("2450"); keyboardDone()
        let message = app.textFields["message-field"]; message.tap(); message.typeText("Demo lunch"); keyboardDone()
        app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.buttons["send-now"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["Avery"].exists); XCTAssertTrue(app.staticTexts["Today"].exists)
        app.buttons["Back"].tap(); XCTAssertEqual(amount.value as? String, "$24.50")
        app.buttons["Cancel"].tap(); app.buttons["Keep editing"].tap(); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].tap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertEqual(app.staticTexts["confirmation-amount"].label, "$24.50")
        XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains("Today"))
        app.buttons["confirmation-done"].tap(); app.buttons["See activity"].tap(); XCTAssertTrue(app.navigationBars["Demo activity"].waitForExistence(timeout: 5))
        let saved = app.staticTexts.matching(identifier: "activity-message").firstMatch; XCTAssertTrue(saved.waitForExistence(timeout: 5)); XCTAssertEqual(saved.label, "Demo lunch"); app.buttons["Close"].tap()
        app.buttons["tab-More"].tap(); app.buttons["reset-demo"].tap(); app.buttons["Reset demo now"].tap()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["$2,486.70"].exists); XCTAssertFalse(app.textFields["first-name"].exists)
        app.buttons["tab-More"].tap(); app.buttons["Simulated activity"].tap(); XCTAssertTrue(app.staticTexts["No demo payments yet"].waitForExistence(timeout: 5))
    }
    func testCurrencyDigitsZerosBackspaceAndSeparatePayment() {
        onboard(); enterJordan()
        let amount = app.textFields["amount-field"]; amount.tap(); dismissKeyboardIntro()
        for (digit, expected) in [("5", "$0.05"), ("0", "$0.50"), ("0", "$5.00"), ("0", "$50.00")] { amount.typeText(digit); XCTAssertEqual(amount.value as? String, expected) }
        amount.typeText(XCUIKeyboardKey.delete.rawValue); XCTAssertEqual(amount.value as? String, "$5.00")
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3)); XCTAssertEqual(amount.value as? String, "$0.00")
        amount.typeText("0005"); XCTAssertEqual(amount.value as? String, "$0.05"); keyboardDone()
        app.buttons["Cancel"].tap(); app.buttons["Discard payment"].tap(); app.buttons["recent-jordan"].tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.value as? String, "$0.00")
    }
    func testMessageLimitAndDiscard() {
        onboard(); enterJordan()
        let message = app.textFields["message-field"]; message.tap(); dismissKeyboardIntro(); message.typeText(String(repeating: "x", count: 145))
        XCTAssertEqual((message.value as? String)?.count, 140); keyboardDone()
        app.buttons["Cancel"].tap(); app.buttons["Discard payment"].tap(); XCTAssertTrue(app.buttons["recipient-search"].waitForExistence(timeout: 5))
    }
    func testScheduledAccountFrequencyAndSingleSubmission() {
        app.terminate(); app.launchArguments = ["--ui-testing", "--demo-screen", "amount"]; app.launch()
        let amount = app.textFields["amount-field"]; amount.tap(); dismissKeyboardIntro(); amount.typeText("2450"); keyboardDone()
        app.swipeUp(); app.buttons["date-picker"].tap(); app.buttons["In 2 days"].tap(); app.buttons["Use selected date"].tap()
        app.buttons["account-picker"].tap(); app.buttons.containing(.staticText, identifier: "AVERY SAVINGS (..5020)").firstMatch.tap()
        app.switches["repeat-toggle"].tap(); app.buttons["Monthly"].tap(); app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.staticTexts["Nov 14, 2026"].exists); XCTAssertTrue(app.staticTexts["Monthly"].exists); XCTAssertTrue(app.staticTexts["AVERY SAVINGS (..5020)"].exists)
        app.buttons["Back"].tap(); XCTAssertTrue(app.buttons["date-picker"].label.contains("Nov 14, 2026")); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].doubleTap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains("Nov 14, 2026"))
        app.buttons["confirmation-done"].tap(); app.buttons["See activity"].tap(); XCTAssertTrue(app.navigationBars["Demo activity"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Jordan Ellis").count, 1); XCTAssertTrue(app.staticTexts["Scheduled • Nov 14, 2026"].exists)
    }
    func testOptionalRecipientFieldsThroughPaymentFlow() {
        onboard()
        for (name, digits, label) in [("Jamie Vale", "", "Jamie Vale"), ("", "000000000", "000-000-000"), ("", "0000000000", "(000) 000-0000"), ("Morgan Vale", "2025550158", "Morgan Vale")] {
            if app.buttons["send-zelle"].exists { app.buttons["send-zelle"].tap() } else { app.buttons["hub-action-1"].tap() }
            app.buttons["add-recipient"].tap()
            if !name.isEmpty { let field = app.textFields["new-name"]; field.tap(); dismissKeyboardIntro(); field.typeText(name); keyboardDone() }
            if !digits.isEmpty { let field = app.textFields["new-number"]; field.tap(); field.typeText(digits); keyboardDone() }
            app.buttons["save-recipient"].tap(); XCTAssertTrue(app.buttons["recipient-search"].waitForExistence(timeout: 5))
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recent-")).firstMatch.tap()
            let amount = app.textFields["amount-field"]; XCTAssertTrue(amount.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts[label].exists); XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Registered as")).count, 0)
            amount.tap(); amount.typeText("500"); keyboardDone(); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].tap()
            XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains(label)); app.buttons["confirmation-done"].tap()
        }
    }
    func testEmptyAndInvalidRecipientForm() {
        onboard(); app.buttons["send-zelle"].tap(); app.buttons["add-recipient"].tap(); app.buttons["save-recipient"].tap()
        XCTAssertTrue(app.staticTexts["recipient-error"].waitForExistence(timeout: 5))
        let number = app.textFields["new-number"]; number.tap(); dismissKeyboardIntro(); number.typeText("123"); keyboardDone(); app.buttons["save-recipient"].tap()
        XCTAssertTrue(app.staticTexts["recipient-error"].label.contains("9 or 10 digits"))
    }
}
