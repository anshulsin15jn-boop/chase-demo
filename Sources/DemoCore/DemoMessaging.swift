import Foundation

/// Provider-neutral, immutable simulation content. This is not a bank alert.
public struct DemoMessage: Equatable, Sendable {
    public let paymentID: UUID
    public let sender: String
    public let cents: Int
    public let destination: String?
    public let body: String
    public let recipientName: String
    public init(payment: Payment) {
        paymentID = payment.id; sender = payment.sender.uppercased(); cents = payment.cents
        destination = DemoMessageDestination.e164(payment.recipient.phoneDigits)
        recipientName = RecipientName.display(payment.recipient, uppercase: true)
        body = "CHASE DEMO - LOCAL SIMULATION: \(sender) recorded a simulated payment of \(Demo.money(cents)) to \(recipientName). No real money was transferred. Independent demo, not a bank payment alert."
    }
    public func transportPayload() throws -> Data {
        guard let destination else { throw DemoMessagingError.unavailable }
        return try JSONEncoder().encode(DemoMessageTransport(paymentID: paymentID.uuidString, to: destination, body: body, sender: sender, recipientName: recipientName, cents: cents))
    }
}
public struct DemoMessageTransport: Equatable, Codable, Sendable {
    public let paymentID: String
    public let to: String
    public let body: String
    public let sender: String
    public let recipientName: String
    public let cents: Int
}
public enum DemoMessageDestination {
    public static func e164(_ phoneDigits: String) -> String? {
        let digits = phoneDigits.trimmingCharacters(in: .whitespacesAndNewlines)
        guard digits.count == 10, PhoneNumber.isASCII(digits) else { return nil }
        return "+1" + digits
    }
}
public enum DemoMessagingError: Error, Equatable { case disabled, unavailable }
public protocol DemoMessageDelivery: Sendable {
    func deliver(_ message: DemoMessage) async throws
}
/// Fail closed. No provider, address discovery, credentials, network or delivery code.
public struct DisabledDemoMessageDelivery: DemoMessageDelivery {
    public init() {}
    public func deliver(_ message: DemoMessage) async throws { throw DemoMessagingError.disabled }
}
/// Posts the immutable payload to a local helper. Twilio credentials never enter the app.
public struct HTTPDemoMessageDelivery: DemoMessageDelivery {
    public let endpoint: URL
    private let relayToken: String
    public init(endpoint: URL, relayToken: String) { self.endpoint = endpoint; self.relayToken = relayToken }
    public func deliver(_ message: DemoMessage) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 25
        request.httpBody = try message.transportPayload()
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DemoMessagingError.unavailable
        }
    }
}
