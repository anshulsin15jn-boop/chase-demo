import XCTest
import DemoCore
@testable import BankingHackathonDemo

final class StoreTests: XCTestCase {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    var date: Date { ISO8601DateFormatter().date(from: "2026-11-12T12:00:00Z")! }
    @MainActor func store(clock: @escaping () -> Date, calendar: @escaping () -> Calendar) -> DemoStore {
        let store = DemoStore(repository: nil, clock: clock, calendarProvider: calendar)
        store.completeOnboarding("Avery"); store.select(Demo.recipients[0]); return store
    }
    @MainActor func testInlineErrorOnlyAfterReviewAndNewDraftStartsAtZero() throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal })
        XCTAssertNil(value.amountError); XCTAssertEqual(value.draft?.amount.formatted, "$0.00")
        value.review(); XCTAssertEqual(value.amountError, "Please tell us an amount."); XCTAssertNil(value.error)
        value.draft?.amount = try CurrencyInput(digits: "500"); value.done(); value.select(Demo.recipients[0])
        XCTAssertEqual(value.draft?.amount.cents, 0); XCTAssertNil(value.amountError)
    }
    @MainActor func testClockRefreshFollowsDefaultTodayAndPreservesExplicitDate() throws {
        var now = date; let cal = calendar
        let value = store(clock: { now }, calendar: { cal })
        let selected = value.draft!.date
        now = cal.date(byAdding: .day, value: 1, to: now)!; value.refreshDay()
        XCTAssertEqual(value.draft?.date, cal.startOfDay(for: now)); XCTAssertFalse(value.meaningful)
        value.selectDate(selected); now = cal.date(byAdding: .day, value: 1, to: now)!; value.refreshDay()
        XCTAssertEqual(value.draft?.date, selected); XCTAssertFalse(value.draft!.usesToday)
        value.draft?.amount = try CurrencyInput(digits: "500"); value.review()
        XCTAssertNotNil(value.error); XCTAssertFalse(value.path.contains(.review)); XCTAssertTrue(value.ledger.payments.isEmpty)
    }
    @MainActor func testCalendarAndTimeZoneAreRechecked() {
        let now = ISO8601DateFormatter().date(from: "2026-11-12T01:00:00Z")!
        var cal = calendar
        let value = store(clock: { now }, calendar: { cal })
        let original = value.draft!.date
        cal.timeZone = TimeZone(identifier: "America/Chicago")!; value.refreshDay()
        XCTAssertNotEqual(value.draft?.date, original)
        XCTAssertEqual(value.calendar.timeZone, cal.timeZone)
        XCTAssertEqual(value.dateLabel(value.draft!.date), "Today")
    }
    @MainActor func testSubmitRechecksStaleExplicitDayAfterReview() async throws {
        var now = date; let cal = calendar
        let value = store(clock: { now }, calendar: { cal })
        value.draft?.amount = try CurrencyInput(digits: "500"); value.selectDate(cal.startOfDay(for: now)); value.review()
        XCTAssertTrue(value.path.contains(.review))
        now = cal.date(byAdding: .day, value: 1, to: now)!
        await value.send()
        XCTAssertTrue(value.ledger.payments.isEmpty); XCTAssertNil(value.submitted); XCTAssertNotNil(value.error)
        XCTAssertEqual(value.ledger.accounts[0].cents, 248670)
    }
    @MainActor func testDefaultTodayAtSubmitUsesFreshClockAndLocalSender() async throws {
        var now = date; let cal = calendar
        let value = store(clock: { now }, calendar: { cal })
        value.draft?.amount = try CurrencyInput(digits: "500"); value.review()
        now = cal.date(byAdding: .day, value: 1, to: now)!
        await value.send()
        XCTAssertEqual(value.submitted?.date, cal.startOfDay(for: now)); XCTAssertEqual(value.submitted?.sender, "Avery")
        XCTAssertEqual(value.accountLabel(value.submitted!.account), "AVERY CHECKING (..5020)")
    }
    @MainActor func testConcurrentSubmissionRecordsExactlyOnePayment() async throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal }); value.draft?.amount = try CurrencyInput(digits: "500")
        async let first: Void = value.send()
        async let second: Void = value.send()
        _ = await (first, second)
        XCTAssertEqual(value.ledger.payments.count, 1); XCTAssertEqual(value.ledger.accounts[0].cents, 248170)
        XCTAssertFalse(value.isSubmitting)
    }
    @MainActor func testResetRetainsOnboardingAndRestoresFixtures() async throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal })
        try value.addRecipient(name: "Jamie Vale", number: "", email: "")
        value.draft?.amount = try CurrencyInput(digits: "500"); await value.send()
        value.done(); value.reset()
        XCTAssertEqual(value.firstName, "Avery"); XCTAssertFalse(value.needsFirstName)
        XCTAssertEqual(value.recipients, Demo.recipients); XCTAssertTrue(value.ledger.payments.isEmpty)
        XCTAssertEqual(value.ledger.accounts, Demo.accounts)
    }
    @MainActor func testBackNavigationPreservesAmountAndSelectedDate() throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal }); let future = cal.date(byAdding: .day, value: 2, to: day)!
        value.draft?.amount = try CurrencyInput(digits: "5000"); value.selectDate(future); value.review(); value.path.removeLast()
        XCTAssertEqual(value.draft?.amount.cents, 5000); XCTAssertEqual(value.draft?.date, future)
        XCTAssertFalse(value.draft!.usesToday)
    }
}
