import Foundation

/// Provider-neutral, immutable simulation content. This is not a delivery implementation.
public struct DemoMessage: Equatable, Sendable {
    public let paymentID: UUID
    public let sender: String
    public let cents: Int
    public let body: String
    public init(payment: Payment) {
        paymentID = payment.id; sender = payment.sender.uppercased(); cents = payment.cents
        body = "CHASE DEMO — LOCAL SIMULATION: \(sender) recorded a simulated payment of \(Demo.money(cents)) to \(RecipientName.display(payment.recipient, uppercase: true)). No real money was transferred. This is an independent demonstration, not a bank payment alert."
    }
}
public enum DemoMessagingError: Error, Equatable { case disabled }
public protocol DemoMessageDelivery: Sendable {
    func deliver(_ message: DemoMessage) async throws
}
/// Fail closed. No provider, address discovery, credentials, network or delivery code.
public struct DisabledDemoMessageDelivery: DemoMessageDelivery {
    public init() {}
    public func deliver(_ message: DemoMessage) async throws { throw DemoMessagingError.disabled }
}
