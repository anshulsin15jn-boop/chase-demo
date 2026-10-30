import XCTest
@testable import DemoCore

final class TransactionPresentationTests: XCTestCase {
    func testZellePendingOnlyOnSameLocalDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let sent = ISO8601DateFormatter().date(from: "2026-10-29T23:00:00Z")!
        let sameDay = sent.addingTimeInterval(3600)
        let nextDay = sent.addingTimeInterval(7 * 3600)
        XCTAssertEqual(TransactionPresentation.status(date: sent, scheduled: false, isZelle: true, now: sameDay, calendar: calendar), "Pending")
        XCTAssertEqual(TransactionPresentation.status(date: sent, scheduled: false, isZelle: true, now: nextDay, calendar: calendar), "Posted")
        XCTAssertEqual(TransactionPresentation.status(date: sent, scheduled: true, isZelle: true, now: sameDay, calendar: calendar), "Scheduled")
        XCTAssertEqual(TransactionPresentation.status(date: sent, scheduled: false, isZelle: false, now: sameDay, calendar: calendar), "Posted")
    }
}
