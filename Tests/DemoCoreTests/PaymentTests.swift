import XCTest
@testable import DemoCore

final class PaymentTests: XCTestCase {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    var now: Date { ISO8601DateFormatter().date(from: "2026-11-12T12:00:00Z")! }
    func draft(_ digits: String = "525", recipient: Recipient = Demo.recipients[0]) throws -> Draft {
        var value = Draft(recipient: recipient, now: now, calendar: calendar); value.amount = try CurrencyInput(digits: digits); return value
    }
    func validate(_ value: Draft, at date: Date? = nil) throws -> Int { try Ledger().validate(value, now: date ?? now, calendar: calendar) }
    func isolated(_ test: (LocalPersistence, UserDefaults) throws -> Void) throws {
        let suite = "ChaseDemo.UnitTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try test(LocalPersistence(defaults: defaults), defaults)
    }
    func testFirstNameTrimmingAndNormalNames() throws {
        for name in ["Avery", "Élodie", "Anne-Marie", "D'Arcy", "O’Neil"] {
            XCTAssertEqual(try LocalProfile(firstName: " \n" + name + " \t").firstName, name)
        }
        for empty in ["", " ", "\t\n"] { XCTAssertThrowsError(try LocalProfile(firstName: empty)) }
    }
    func testOnboardingAndRecipientPersistence() throws {
        try isolated { repository, _ in
            var state = try repository.load(); XCTAssertNil(state.profile)
            try state.onboard(firstName: "  Avery  ")
            try state.addRecipient(name: "Jamie Vale", number: "")
            try state.addRecipient(name: "", number: "000000000")
            try repository.save(state)
            let loaded = try repository.load()
            XCTAssertEqual(loaded.profile?.firstName, "Avery"); XCTAssertEqual(loaded.recipients.count, 11)
            XCTAssertEqual(loaded.recipients[0].phoneDigits, "000000000")
            XCTAssertEqual(loaded.recipients[0].displayName, "000-000-000")
        }
    }
    func testLegacyMigrationPreservesActivityBalancesRecipientsAndDates() throws {
        try isolated { repository, defaults in
            var old = LocalState()
            let original = try old.ledger.submit(draft("1250"), id: UUID(), sender: "Avery", now: now, calendar: calendar)
            old.recipients.append(Recipient(id: "legacy-local", name: "Jamie Vale", phoneDigits: "2025550155"))
            var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as! [String: Any]
            json.removeValue(forKey: "profile")
            json["recipients"] = old.recipients.map { ["id": $0.id, "name": $0.name, "contact": $0.contact] }
            defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: LocalPersistence.storageKey)
            var migrated = try repository.load()
            XCTAssertNil(migrated.profile); XCTAssertEqual(migrated.recipients.count, 10)
            XCTAssertEqual(migrated.recipients.last?.phoneDigits, "2025550155")
            XCTAssertEqual(migrated.ledger.accounts[0].cents, 247420)
            XCTAssertEqual(migrated.ledger.payments.first?.date, original.date)
            try migrated.onboard(firstName: "Avery"); try repository.save(migrated)
            let reloaded = try repository.load()
            XCTAssertEqual(reloaded.ledger.payments, migrated.ledger.payments)
            XCTAssertEqual(reloaded.ledger.accounts, migrated.ledger.accounts)
            XCTAssertEqual(reloaded.recipients, migrated.recipients)
            XCTAssertEqual(reloaded.profile?.firstName, "Avery")
        }
    }
    func testPersonalizedAccountsKeepSeparateTypesAndTwoPeriods() {
        XCTAssertEqual(Demo.accounts[0].displayLabel(firstName: "Avery"), "AVERY CHECKING (..5020)")
        XCTAssertEqual(Demo.accounts[1].displayLabel(firstName: "Avery"), "AVERY SAVINGS (..5020)")
        XCTAssertEqual(Demo.accounts[0].displayLabel(firstName: "Élodie-Anne"), "ÉLODIE-ANNE CHECKING (..5020)")
    }
    func testTodayFormattingAtLocalBoundary() {
        var chicago = calendar; chicago.timeZone = TimeZone(identifier: "America/Chicago")!
        let date = ISO8601DateFormatter().date(from: "2026-01-01T00:05:00Z")!
        let later = ISO8601DateFormatter().date(from: "2026-01-01T07:00:00Z")!
        XCTAssertEqual(LocalDay.label(date, now: later, calendar: calendar), "Today")
        XCTAssertEqual(LocalDay.label(date, now: later, calendar: chicago), "Dec 31, 2025")
        XCTAssertEqual(LocalDay.label(later, now: later, calendar: chicago), "Today")
    }
    func testDefaultTodayFollowsClockButExplicitDateDoesNot() throws {
        let next = calendar.date(byAdding: .day, value: 1, to: now)!
        var value = try draft(); XCTAssertTrue(value.usesToday)
        value.refresh(now: next, calendar: calendar)
        XCTAssertEqual(value.date, calendar.startOfDay(for: next))
        value.selectDate(calendar.startOfDay(for: now), calendar: calendar); XCTAssertFalse(value.usesToday)
        value.refresh(now: next, calendar: calendar)
        XCTAssertEqual(value.date, calendar.startOfDay(for: now))
        XCTAssertThrowsError(try validate(value, at: next)) { XCTAssertEqual($0 as? PaymentError, .date) }
        value.selectToday(now: next, calendar: calendar); XCTAssertNoThrow(try validate(value, at: next))
    }
    func testHistoricalPaymentDatesNeverRefresh() throws {
        var ledger = Ledger(); var value = try draft()
        let payment = try ledger.submit(value, id: UUID(), sender: "Avery", now: now, calendar: calendar)
        value.refresh(now: calendar.date(byAdding: .day, value: 3, to: now)!, calendar: calendar)
        XCTAssertEqual(ledger.payments[0].date, payment.date)
        XCTAssertNotEqual(value.date, payment.date)
    }
    func testExplicitCivilDaySurvivesTimeZoneChange() throws {
        var chicago = calendar; chicago.timeZone = TimeZone(identifier: "America/Chicago")!
        var value = try draft(); value.selectDate(calendar.startOfDay(for: now), calendar: calendar)
        value.refresh(now: now, calendar: chicago)
        let effective = value.effectiveDate(now: now, calendar: chicago)
        XCTAssertEqual(chicago.component(.day, from: effective), 12)
        XCTAssertEqual(value.date, calendar.startOfDay(for: now))
    }
    func testLegacyUTCHistoricalCalendarDaySurvivesLocalFormatting() throws {
        var ledger = Ledger()
        let payment = try ledger.submit(draft(), id: UUID(), sender: "Avery", now: now, calendar: calendar)
        var fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(payment)) as! [String: Any]
        fields.removeValue(forKey: "timeZoneIdentifier")
        let legacy = try JSONDecoder().decode(Payment.self, from: JSONSerialization.data(withJSONObject: fields))
        var chicago = calendar; chicago.timeZone = TimeZone(identifier: "America/Chicago")!
        let later = calendar.date(byAdding: .day, value: 3, to: now)!
        XCTAssertEqual(LocalDay.recordLabel(legacy, now: later, calendar: chicago), "Nov 12, 2026")
        XCTAssertEqual(legacy.date, payment.date)
    }
    func testAutomaticCurrencyDigitSequence() throws {
        var value = CurrencyInput(); XCTAssertEqual(value.formatted, "$0.00")
        for (digit, result) in [("5", "$0.05"), ("0", "$0.50"), ("0", "$5.00"), ("0", "$50.00")] {
            try value.append(digit); XCTAssertEqual(value.formatted, result)
        }
        XCTAssertEqual(value.cents, 5000)
    }
    func testCurrencyZerosDeletionAndThousands() throws {
        var value = try CurrencyInput(digits: "00005000")
        XCTAssertEqual(value.digits, "00005000"); XCTAssertEqual(value.cents, 5000)
        value.backspace(); XCTAssertEqual(value.formatted, "$5.00")
        for _ in 0..<8 { value.backspace() }
        XCTAssertEqual(value.formatted, "$0.00"); XCTAssertEqual(value.digits, "")
        try value.append("123456789"); XCTAssertEqual(value.formatted, "$1,234,567.89")
    }
    func testPastedDigitsInvalidCharactersAndOverflowAreAtomic() throws {
        var value = try CurrencyInput(digits: "50")
        try value.append("00"); XCTAssertEqual(value.cents, 5000)
        let before = value
        for input in ["12.34", "1,234", "abc", "5\n", "１２", "١٢", "+5"] {
            XCTAssertThrowsError(try value.append(input)); XCTAssertEqual(value, before)
        }
        value = try CurrencyInput(digits: String(Int.max)); let max = value
        XCTAssertThrowsError(try value.append("0")); XCTAssertEqual(value, max)
        XCTAssertThrowsError(try CurrencyInput(digits: "9999999999999999999"))
    }
    func testPositiveAmountsBalanceAndLimitValidation() throws {
        XCTAssertThrowsError(try validate(draft(""))) { XCTAssertEqual($0 as? PaymentError, .invalid) }
        XCTAssertThrowsError(try validate(draft("000")))
        XCTAssertEqual(try validate(draft("1")), 1)
        XCTAssertEqual(try validate(draft("248670")), 248670)
        XCTAssertThrowsError(try validate(draft("248671"))) { XCTAssertEqual($0 as? PaymentError, .balance) }
        XCTAssertThrowsError(try validate(draft("1000001"))) { XCTAssertEqual($0 as? PaymentError, .limit) }
    }
    func testRecipientNameOnlyNumberOnlyCombinedAndEmail() throws {
        let nameOnly = try Recipient.create(name: " Jamie Vale ", number: "")
        XCTAssertEqual(nameOnly.displayName, "Jamie Vale"); XCTAssertEqual(nameOnly.initial, "JV")
        XCTAssertEqual(nameOnly.subtitle, ""); XCTAssertFalse(nameOnly.registered)
        let numberOnly = try Recipient.create(name: "", number: "202555014")
        XCTAssertEqual(numberOnly.displayName, "202-555-014"); XCTAssertEqual(numberOnly.name, "")
        XCTAssertEqual(numberOnly.initial, ""); XCTAssertEqual(numberOnly.subtitle, "")
        let combined = try Recipient.create(name: "Morgan Vale", number: "2025550158")
        XCTAssertEqual(combined.subtitle, "(202) 555-0158")
        XCTAssertEqual(try Recipient.create(name: "", number: "", email: "demo@example.com").displayName, "demo@example.com")
    }
    func testNineTenDigitsAndLeadingZerosAreStrings() throws {
        XCTAssertEqual(try PhoneNumber.validate("000000000"), "000000000")
        XCTAssertEqual(PhoneNumber.display("000000000"), "000-000-000")
        XCTAssertEqual(PhoneNumber.display("0000000000"), "(000) 000-0000")
        let value = try Recipient.create(name: "", number: "0000000000")
        let encoded = try JSONEncoder().encode(value)
        let fields = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        XCTAssertEqual(fields["phoneDigits"] as? String, "0000000000"); XCTAssertNil(fields["contact"])
        XCTAssertEqual(try JSONDecoder().decode(Recipient.self, from: encoded), value)
    }
    func testEmptyRecipientAndInvalidPhoneEmailInput() {
        for name in ["", " \n\t"] { XCTAssertThrowsError(try Recipient.create(name: name, number: " \n")) }
        for phone in ["123", "12345678", "12345678901", "202-555-014", "abcdefghij", "１２３４５６７８９", "١٢٣٤٥٦٧٨٩", "202555014x"] {
            XCTAssertThrowsError(try Recipient.create(name: "Jamie", number: phone))
        }
        XCTAssertThrowsError(try Recipient.create(name: "Jamie", number: "", email: "not-an-email"))
    }
    func testSearchAcrossMissingNamesAndContacts() throws {
        let recipients = [try Recipient.create(name: "Jamie Vale", number: ""), try Recipient.create(name: "", number: "000000000"), try Recipient.create(name: "", number: "", email: "demo@example.com")]
        XCTAssertEqual(Demo.filter(recipients, query: "JAMIE").first?.displayName, "Jamie Vale")
        XCTAssertEqual(Demo.filter(recipients, query: "000-000-000").first?.phoneDigits, "000000000")
        XCTAssertEqual(Demo.filter(recipients, query: "DEMO@EXAMPLE.COM").count, 1)
        XCTAssertTrue(Demo.filter(recipients, query: "missing").isEmpty)
        XCTAssertEqual(Demo.filter(Demo.recipients, query: "2025550146").first?.id, "jordan")
    }
    func testDuplicateRecipientCreationAndReload() throws {
        var state = LocalState(); try state.addRecipient(name: "Jamie Vale", number: "")
        XCTAssertThrowsError(try state.addRecipient(name: "jamie vale", number: ""))
        try state.addRecipient(name: "", number: "000000000")
        XCTAssertThrowsError(try state.addRecipient(name: "Another name", number: "000000000"))
        XCTAssertEqual(state.recipients.count, 11)
        let restored = try JSONDecoder().decode(LocalState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.recipients, state.recipients)
    }
    func testPaymentsWithRecipientsMissingEitherFieldAndImmutableSnapshot() throws {
        for recipient in [try Recipient.create(name: "Jamie Vale", number: ""), try Recipient.create(name: "", number: "000000000"), try Recipient.create(name: "Morgan Vale", number: "2025550158")] {
            var ledger = Ledger(); var value = try draft("500", recipient: recipient); let id = UUID()
            let payment = try ledger.submit(value, id: id, sender: "Avery", now: now, calendar: calendar)
            value.message = "Changed draft"; value.amount = CurrencyInput()
            XCTAssertEqual(payment.cents, 500); XCTAssertEqual(payment.message, "")
            XCTAssertEqual(payment.sender, "Avery"); XCTAssertEqual(payment.recipient, recipient)
            XCTAssertThrowsError(try ledger.submit(value, id: id, sender: "Avery", now: now, calendar: calendar))
            XCTAssertEqual(ledger.payments.count, 1); XCTAssertEqual(ledger.accounts[0].cents, 248170)
        }
    }
    func testSchedulingDoesNotDeductAndPreservesExplicitDateAndFrequency() throws {
        var ledger = Ledger(); var value = try draft(); let future = calendar.date(byAdding: .day, value: 3, to: now)!
        value.selectDate(future, calendar: calendar); value.frequency = .monthly
        let payment = try ledger.submit(value, id: UUID(), sender: "Avery", now: now, calendar: calendar)
        XCTAssertTrue(payment.scheduled); XCTAssertEqual(payment.date, future); XCTAssertEqual(payment.frequency, .monthly)
        XCTAssertEqual(ledger.accounts[0].cents, 248670)
        XCTAssertEqual(try JSONDecoder().decode(Ledger.self, from: JSONEncoder().encode(ledger)).payments, ledger.payments)
    }
    func testMessageAccountValidationAndReset() throws {
        var value = try draft(); value.message = String(repeating: "x", count: 140); XCTAssertNoThrow(try validate(value))
        value.message += "x"; XCTAssertThrowsError(try validate(value)); value.message = ""; value.accountID = "missing"; XCTAssertThrowsError(try validate(value))
        var ledger = Ledger(); try ledger.submit(draft(), id: UUID(), sender: "Avery", now: now, calendar: calendar)
        ledger = Ledger(); XCTAssertTrue(ledger.payments.isEmpty); XCTAssertEqual(ledger.accounts, Demo.accounts)
    }
}
