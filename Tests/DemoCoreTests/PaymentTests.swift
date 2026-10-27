import XCTest
@testable import DemoCore
final class PaymentTests: XCTestCase {
    func draft(_ amount: String = "5.25") -> Draft { var d = Draft(recipient: Demo.recipients[0], date: Demo.today); d.amount = amount; return d }
    func testExactCentsAndInvalidAmounts() throws {
        XCTAssertEqual(Demo.cents("0.29"), 29)
        for value in ["", "-1", "0", "0.00", "1.234", "NaN", "1e3", ".", "12,34"] { XCTAssertThrowsError(try Ledger().validate(draft(value)), value) }
        XCTAssertEqual(try Ledger().validate(draft("0.01")), 1)
        XCTAssertThrowsError(try Ledger().validate(draft("2486.71")))
        XCTAssertThrowsError(try Ledger().validate(draft("10000.01")))
    }
    func testSubmissionSnapshotAndDuplicate() throws {
        var ledger = Ledger(); var d = draft(); let id = UUID()
        let p = try ledger.submit(d, id: id); d.message = "Changed draft"
        XCTAssertEqual(p.message, ""); XCTAssertEqual(ledger.accounts[0].cents, 248145)
        XCTAssertThrowsError(try ledger.submit(d, id: id)); XCTAssertEqual(ledger.payments.count, 1)
        XCTAssertEqual(ledger.accounts[0].cents, 248145)
    }
    func testSchedulingAndDatePersistence() throws {
        var ledger = Ledger(); var d = draft(); d.date = Demo.calendar.date(byAdding: .day, value: 3, to: Demo.today)!; d.frequency = .monthly
        let p = try ledger.submit(d, id: UUID())
        XCTAssertTrue(p.scheduled); XCTAssertEqual(p.date, d.date); XCTAssertEqual(p.frequency, .monthly); XCTAssertEqual(ledger.accounts[0].cents, 248670)
        d.date = Demo.calendar.date(byAdding: .day, value: -1, to: Demo.today)!
        XCTAssertThrowsError(try ledger.validate(d))
    }
    func testMessageAndAccountValidation() {
        var d = draft(); d.message = String(repeating: "a", count: 140); XCTAssertNoThrow(try Ledger().validate(d))
        d.message += "b"; XCTAssertThrowsError(try Ledger().validate(d))
        d.message = ""; d.accountID = "missing"; XCTAssertThrowsError(try Ledger().validate(d))
    }
    func testSearchAndSyntheticContacts() {
        XCTAssertEqual(Demo.filter(Demo.recipients, query: "JORDAN").count, 1)
        XCTAssertEqual(Demo.filter(Demo.recipients, query: "2025550146").first?.id, "jordan")
        XCTAssertEqual(Demo.filter(Demo.recipients, query: "maple@").first?.id, "club")
        XCTAssertTrue(Demo.filter(Demo.recipients, query: "unknown").isEmpty)
        XCTAssertTrue(Demo.recipients.allSatisfy { Demo.validContact($0.contact) })
        XCTAssertFalse(Demo.validContact("person@real.test")); XCTAssertFalse(Demo.validContact("123"))
    }
    func testEncodingAndReset() throws {
        var ledger = Ledger(); try ledger.submit(draft(), id: UUID())
        let decoded = try JSONDecoder().decode(Ledger.self, from: JSONEncoder().encode(ledger)); XCTAssertEqual(decoded.payments, ledger.payments)
        ledger = Ledger(); XCTAssertTrue(ledger.payments.isEmpty); XCTAssertEqual(ledger.accounts, Demo.accounts)
    }
}
