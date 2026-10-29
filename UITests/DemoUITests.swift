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
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); dismissKeyboardIntro(); name.typeText("Avery"); keyboardDone()
        let last = app.textFields["last-name"]; last.tap(); last.typeText("Collins"); keyboardDone()
        app.buttons["enter-demo"].tap(); XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5))
    }
    func keyboardDone() { app.buttons.matching(identifier: "keyboard-done").firstMatch.tap() }
    func enterJordan() { app.buttons["send-zelle"].tap(); app.buttons["recent-jordan"].tap() }

    func testTransactionsSearchDetailsAndAccountSelection() {
        onboard()
        XCTAssertFalse(app.buttons["tab-Transactions"].exists)
        app.staticTexts["account-label-checking"].tap()
        XCTAssertTrue(app.buttons["account-pay"].waitForExistence(timeout: 5))
        app.buttons["see-all-transactions"].tap()
        XCTAssertTrue(app.buttons["transaction-sample-checking-0"].waitForExistence(timeout: 5))
        app.buttons["transaction-sample-checking-0"].tap()
        XCTAssertTrue(app.staticTexts["Transaction details"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        let search = app.textFields["transaction-search"]
        search.tap(); dismissKeyboardIntro(); search.typeText("AMAZON")
        XCTAssertTrue(app.buttons["transaction-sample-checking-2"].exists)
        XCTAssertFalse(app.buttons["transaction-sample-checking-0"].exists)
        app.buttons["Clear search"].tap()
        app.buttons["transaction-account"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "SAVINGS")).firstMatch.tap()
        XCTAssertTrue(app.buttons["transaction-sample-savings-0"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["transaction-sample-checking-0"].exists)
    }

    func testFirstNameMigrationAndPersistence() {
        app.terminate()
        let suite = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--persistent-suite", suite, "--seed-legacy"]; app.launch()
        XCTAssertTrue(app.textFields["first-name"].waitForExistence(timeout: 5))
        app.buttons["enter-demo"].tap(); XCTAssertTrue(app.staticTexts["onboarding-error"].exists)
        XCTAssertEqual(app.textFields["first-name"].value as? String, "Avery")
        let last = app.textFields["last-name"]; last.tap(); dismissKeyboardIntro(); last.typeText("  Collins  "); keyboardDone(); app.buttons["enter-demo"].tap()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5))
        let checking = app.staticTexts["account-label-checking"].label
        let savings = app.staticTexts["account-label-savings"].label
        XCTAssertTrue(checking.hasPrefix("AVERY COLLINS CHECKING (..")); XCTAssertTrue(savings.hasPrefix("AVERY COLLINS SAVINGS (.."))
        app.buttons["tab-More"].tap(); app.buttons["Simulated activity"].tap(); XCTAssertTrue(app.staticTexts["$12.50"].waitForExistence(timeout: 5)); app.buttons["Close"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5)); XCTAssertFalse(app.textFields["first-name"].exists)
        XCTAssertEqual(app.staticTexts["account-label-checking"].label, checking); XCTAssertEqual(app.staticTexts["account-label-savings"].label, savings)
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
        XCTAssertTrue(app.buttons["send-now"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["AVERY COLLINS"].exists); XCTAssertTrue(app.staticTexts["Today"].exists)
        app.buttons["Back"].tap(); XCTAssertEqual(amount.value as? String, "$24.50")
        app.buttons["Cancel"].tap(); app.buttons["Keep editing"].tap(); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].tap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertEqual(app.staticTexts["confirmation-amount"].label, "$24.50")
        XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains("coming on Nov 12, 2026."))
        app.buttons["confirmation-done"].tap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForNonExistence(timeout: 5))
        app.buttons["See activity"].staticTexts["See activity"].tap(); XCTAssertTrue(app.navigationBars["Demo activity"].waitForExistence(timeout: 5))
        let saved = app.staticTexts.matching(identifier: "activity-message").firstMatch; XCTAssertTrue(saved.waitForExistence(timeout: 5)); XCTAssertEqual(saved.label, "Demo lunch"); app.buttons["Close"].tap()
        app.buttons["tab-Accounts"].tap()
        app.staticTexts["account-label-checking"].tap()
        let number = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "transaction-number-")).firstMatch
        XCTAssertTrue(number.waitForExistence(timeout: 5)); XCTAssertEqual(number.label, "2025550146")
        let status = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "transaction-status-")).firstMatch
        XCTAssertTrue(status.exists); XCTAssertEqual(status.label, "Pending")
        app.buttons["Back"].tap()
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
        app.buttons["Cancel"].tap(); app.buttons["Discard payment"].tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Discard payment"].waitForNonExistence(timeout: 5))
        app.buttons["recent-jordan"].staticTexts["Jordan Ellis"].tap()
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
        app.buttons["account-picker"].tap(); app.buttons.containing(.staticText, identifier: "AVERY COLLINS SAVINGS (..6841)").firstMatch.tap()
        app.switches["repeat-toggle"].tap(); app.buttons["Monthly"].tap(); app.swipeUp(); app.buttons["review-send"].tap()
        XCTAssertTrue(app.staticTexts["Nov 14, 2026"].exists); XCTAssertTrue(app.staticTexts["Monthly"].exists); XCTAssertTrue(app.staticTexts["AVERY COLLINS SAVINGS (..6841)"].exists)
        app.buttons["Back"].tap(); XCTAssertTrue(app.buttons["date-picker"].label.contains("Nov 14, 2026")); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].doubleTap()
        XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["confirmation-text"].label.contains("Nov 14, 2026"))
        app.buttons["confirmation-done"].tap(); app.buttons["See activity"].tap(); XCTAssertTrue(app.navigationBars["Demo activity"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Jordan Ellis").count, 1); XCTAssertTrue(app.staticTexts["Scheduled • Nov 14, 2026"].exists)
    }
    func testOptionalRecipientFieldsThroughPaymentFlow() {
        onboard()
        for (name, digits, label) in [("Jamie Vale", "", "Jamie Vale"), ("", "000000000", "000-000-000"), ("", "0000000000", "(000) 000-0000"), ("Alexandra-Marie O'Neil Rivera Bennett", "2025550158", "Alexandra-Marie O'Neil Rivera Bennett")] {
            if app.buttons["send-zelle"].exists { app.buttons["send-zelle"].tap() } else { app.buttons["hub-action-1"].tap() }
            app.buttons["add-recipient"].tap()
            if !name.isEmpty { let field = app.textFields["new-name"]; field.tap(); dismissKeyboardIntro(); field.typeText(name); keyboardDone() }
            if !digits.isEmpty { let field = app.textFields["new-number"]; field.tap(); field.typeText(digits); keyboardDone() }
            app.buttons["save-recipient"].tap(); XCTAssertTrue(app.buttons["recipient-search"].waitForExistence(timeout: 5))
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recent-")).firstMatch.tap()
            let amount = app.textFields["amount-field"]; XCTAssertTrue(amount.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts[label].exists)
            XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Registered as")).count, name.isEmpty ? 0 : 1)
            XCTAssertTrue(app.staticTexts["Personal account"].exists)
            XCTAssertTrue(app.staticTexts["Zelle® ID active since Feb 2025"].exists)
            let avatar = app.descendants(matching: .any).matching(identifier: "recipient-avatar").firstMatch
            XCTAssertTrue(avatar.label.contains("demo Zelle badge"))
            let metadata = app.descendants(matching: .any).matching(identifier: "recipient-active-since").firstMatch
            XCTAssertGreaterThan(amount.frame.minY, metadata.frame.maxY)
            amount.tap(); amount.typeText("500"); keyboardDone(); app.swipeUp(); app.buttons["review-send"].tap(); app.buttons["send-now"].tap()
            XCTAssertTrue(app.buttons["confirmation-done"].waitForExistence(timeout: 5))
            let expectedName = label.uppercased()
            XCTAssertEqual(app.staticTexts["recipient-name"].label, expectedName)
            XCTAssertTrue(app.staticTexts["confirmation-text"].label.hasPrefix("We'll let \(expectedName) know your payment is coming on Nov 12, 2026."))
            XCTAssertEqual(app.staticTexts["confirmation-amount"].label, "$5.00")
            XCTAssertTrue(avatar.label.contains("demo Zelle badge"))
            if !name.isEmpty { XCTAssertEqual(app.staticTexts["recipient-registration"].label, "Registered as \(expectedName)") }
            else { XCTAssertFalse(app.staticTexts["recipient-registration"].exists) }
            app.swipeUp()
            XCTAssertEqual(app.staticTexts["siri-explanation"].label, "Add a Siri shortcut, such as “Pay \(expectedName)” to save time when sending money.")
            XCTAssertTrue(app.buttons["add-to-siri"].exists)
            if name == "Jamie Vale" {
                app.buttons["add-to-siri"].tap(); XCTAssertTrue(app.navigationBars["Demo information"].waitForExistence(timeout: 5)); app.buttons["Close"].tap()
            }
            app.buttons["confirmation-done"].tap()
        }
    }
    func testEmptyAndInvalidRecipientForm() {
        onboard(); app.buttons["send-zelle"].tap(); app.buttons["add-recipient"].tap(); app.buttons["save-recipient"].tap()
        XCTAssertTrue(app.staticTexts["recipient-error"].waitForExistence(timeout: 5))
        let number = app.textFields["new-number"]; number.tap(); dismissKeyboardIntro(); number.typeText("123"); keyboardDone(); app.buttons["save-recipient"].tap()
        XCTAssertTrue(app.staticTexts["recipient-error"].label.contains("9 or 10 digits"))
    }
    func testPersonalDetailsPersistWithoutRegeneratingAccounts() {
        app.terminate(); app.launchArguments = ["--ui-testing", "--persistent-suite", UUID().uuidString]; app.launch()
        onboard()
        let checking = app.staticTexts["account-label-checking"].label
        let savings = app.staticTexts["account-label-savings"].label
        let balance = app.staticTexts["account-balance-checking"].label
        app.buttons["tab-More"].tap(); app.buttons["Personal details"].staticTexts["Personal details"].tap()
        XCTAssertTrue(app.textFields["profile-first-name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["profile-first-name"].value as? String, "Avery")
        XCTAssertEqual(app.textFields["profile-last-name"].value as? String, "Collins")
        let middle = app.textFields["profile-middle-name"]; middle.tap(); middle.typeText("Lane"); keyboardDone(); app.buttons["save-profile"].tap()
        XCTAssertTrue(app.buttons["save-profile"].waitForNonExistence(timeout: 5)); app.buttons["tab-Accounts"].tap()
        let updated = app.staticTexts["account-label-checking"].label
        XCTAssertEqual(updated, checking.replacingOccurrences(of: "AVERY COLLINS", with: "AVERY LANE COLLINS"))
        XCTAssertEqual(app.staticTexts["account-label-savings"].label, savings.replacingOccurrences(of: "AVERY COLLINS", with: "AVERY LANE COLLINS"))
        XCTAssertEqual(app.staticTexts["account-balance-checking"].label, balance)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["send-zelle"].waitForExistence(timeout: 5)); XCTAssertFalse(app.textFields["last-name"].exists)
        XCTAssertEqual(app.staticTexts["account-label-checking"].label, updated)
        XCTAssertEqual(app.staticTexts["account-balance-checking"].label, balance)
    }
}
