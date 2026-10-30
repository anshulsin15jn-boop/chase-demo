import XCTest
@testable import DemoCore

final class DemoMessagingTests: XCTestCase {
    func testMessageContractUsesSnapshotAndIdentifiesSimulation() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000); let calendar = Calendar(identifier: .gregorian)
        var ledger = Ledger(); var draft = Draft(recipient: Demo.recipients[0], now: now, calendar: calendar)
        draft.amount = try CurrencyInput(digits: "12345")
        let payment = try ledger.submit(draft, id: UUID(), sender: "Élodie Anne O'Neil", now: now, calendar: calendar)
        let message = DemoMessage(payment: payment)
        XCTAssertEqual(message.sender, "ÉLODIE ANNE O'NEIL"); XCTAssertEqual(message.cents, 12345); XCTAssertEqual(message.paymentID, payment.id)
        XCTAssertEqual(message.destination, "+12025550146")
        XCTAssertTrue(message.body.contains("LOCAL SIMULATION")); XCTAssertTrue(message.body.contains("$123.45"))
        XCTAssertTrue(message.body.contains("No real money was transferred"))
        XCTAssertFalse(message.body.contains("Chase | Zelle"))
        let payload = try JSONDecoder().decode(DemoMessageTransport.self, from: try message.transportPayload())
        XCTAssertEqual(payload.paymentID, payment.id.uuidString); XCTAssertEqual(payload.to, "+12025550146")
        XCTAssertEqual(payload.sender, message.sender)
        XCTAssertEqual(payload.recipientName, message.recipientName)
        XCTAssertEqual(payload.cents, message.cents)
        XCTAssertFalse(payload.body.contains("https://"))
        XCTAssertEqual(payload.body, message.body); XCTAssertTrue(payload.body.contains("ÉLODIE ANNE O'NEIL"))
        draft.amount = CurrencyInput(); XCTAssertEqual(DemoMessage(payment: payment), message)
    }
    func testDestinationRequiresTenDigitNumber() throws {
        XCTAssertEqual(DemoMessageDestination.e164("2025550146"), "+12025550146")
        XCTAssertNil(DemoMessageDestination.e164("202555014"))
        XCTAssertNil(DemoMessageDestination.e164(""))
        let now = Date(); let calendar = Calendar(identifier: .gregorian)
        var ledger = Ledger()
        var draft = Draft(recipient: try Recipient.create(name: "Jamie Vale", number: ""), now: now, calendar: calendar)
        draft.amount = try CurrencyInput(digits: "500")
        let payment = try ledger.submit(draft, id: UUID(), sender: "Avery Collins", now: now, calendar: calendar)
        let message = DemoMessage(payment: payment)
        XCTAssertNil(message.destination)
        XCTAssertThrowsError(try message.transportPayload()) { XCTAssertEqual($0 as? DemoMessagingError, .unavailable) }
    }
    func testDeliveryIsDisabled() async {
        do {
            let now = Date(); let calendar = Calendar(identifier: .gregorian)
            var ledger = Ledger(); var draft = Draft(recipient: Demo.recipients[0], now: now, calendar: calendar)
            draft.amount = try CurrencyInput(digits: "500")
            let payment = try ledger.submit(draft, id: UUID(), sender: "Avery Collins", now: now, calendar: calendar)
            try await DisabledDemoMessageDelivery().deliver(DemoMessage(payment: payment))
            XCTFail("Delivery must remain disabled")
        } catch { XCTAssertEqual(error as? DemoMessagingError, .disabled) }
    }
}
