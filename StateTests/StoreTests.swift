import XCTest
import DemoCore
@testable import BankingHackathonDemo

final class StoreTests: XCTestCase {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    var date: Date { ISO8601DateFormatter().date(from: "2026-11-12T12:00:00Z")! }
    @MainActor func store(clock: @escaping () -> Date, calendar: @escaping () -> Calendar, messaging: DemoMessageDelivery = DisabledDemoMessageDelivery()) -> DemoStore {
        let store = DemoStore(repository: nil, clock: clock, calendarProvider: calendar, initialState: LocalState(accountsInitialized: true), messaging: messaging)
        store.completeOnboarding("Avery", lastName: "Collins"); store.select(Demo.recipients[0]); return store
    }
    @MainActor func testInlineErrorOnlyAfterReviewAndNewDraftStartsAtZero() throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal })
        XCTAssertFalse(value.sendsDemoMessages)
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
        XCTAssertEqual(value.submitted?.date, cal.startOfDay(for: now)); XCTAssertEqual(value.submitted?.sender, "Avery Collins")
        XCTAssertEqual(value.accountLabel(value.submitted!.account), "AVERY COLLINS CHECKING (..5020)")
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
    @MainActor func testEditingNameKeepsAccountsDraftAndPaymentSnapshots() async throws {
        let day = date, cal = calendar
        let value = store(clock: { day }, calendar: { cal })
        let suffixes = value.ledger.accounts.map(\.suffix)
        value.draft?.amount = try CurrencyInput(digits: "500"); await value.send()
        let submitted = value.submitted!
        try value.updateProfile(firstName: "Élodie", lastName: "O'Neil", middleName: "Anne")
        XCTAssertEqual(value.senderIdentity, "ÉLODIE ANNE O'NEIL")
        XCTAssertEqual(value.ledger.accounts.map(\.suffix), suffixes)
        XCTAssertEqual(value.submitted, submitted); XCTAssertEqual(value.ledger.payments, [submitted])
        XCTAssertEqual(submitted.sender, "Avery Collins"); XCTAssertEqual(submitted.account.label, "AVERY COLLINS CHECKING (..5020)")
        XCTAssertEqual(value.draft?.amount.cents, 500)
    }
    @MainActor func testSubmitSucceedsWhenDeliveryFails() async throws {
        let day = date, cal = calendar
        let recording = RecordingDelivery()
        let value = store(clock: { day }, calendar: { cal }, messaging: recording)
        XCTAssertTrue(value.sendsDemoMessages)
        value.draft?.amount = try CurrencyInput(digits: "500"); await value.send()
        await value.waitForMessaging()
        XCTAssertEqual(value.ledger.payments.count, 1); XCTAssertNotNil(value.submitted)
        XCTAssertEqual(recording.delivered.count, 1)
        XCTAssertEqual(recording.delivered[0].sender, "AVERY COLLINS")
        XCTAssertEqual(recording.delivered[0].cents, 500)
        XCTAssertEqual(recording.delivered[0].destination, "+12025550146")
        XCTAssertTrue(recording.delivered[0].body.contains("$5.00"))
        XCTAssertFalse(recording.delivered[0].body.contains("Chase | Zelle"))
    }
}

final class RecordingDelivery: DemoMessageDelivery, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var delivered: [DemoMessage] = []
    func deliver(_ message: DemoMessage) async throws {
        lock.lock(); delivered.append(message); lock.unlock()
        throw DemoMessagingError.disabled
    }
}
