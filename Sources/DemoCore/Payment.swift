import Foundation
public struct Recipient: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let contact: String
    public var initial: String { String(name.prefix(1)) }
    public init(id: String, name: String, contact: String) { self.id = id; self.name = name; self.contact = contact }
}
public struct Account: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let label: String
    public var cents: Int
    public init(id: String, label: String, cents: Int) { self.id = id; self.label = label; self.cents = cents }
}
public enum Frequency: String, CaseIterable, Codable, Sendable { case once = "Once", weekly = "Weekly", monthly = "Monthly" }
public struct Draft: Equatable, Codable, Sendable {
    public var recipient: Recipient
    public var amount = ""
    public var message = ""
    public var accountID = "checking"
    public var date: Date
    public var frequency: Frequency = .once
    public init(recipient: Recipient, date: Date) { self.recipient = recipient; self.date = date }
}
public struct Payment: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let recipient: Recipient
    public let cents: Int
    public let message: String
    public let account: Account
    public let date: Date
    public let frequency: Frequency
    public let scheduled: Bool
    public let sender: String
}
public enum PaymentError: String, Error { case invalid = "Enter a positive amount with at most two decimal places.", limit = "This amount exceeds the $10,000.00 demo limit.", balance = "This amount exceeds your available demo balance.", date = "Choose today or a future demo date.", message = "Messages can contain up to 140 characters.", duplicate = "This payment has already been submitted.", account = "Choose a demo account." }
public enum Demo {
    public static let sender = "Avery Collins"
    public static let limit = 1_000_000
    public static let calendar: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }()
    public static let today = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12))!
    public static let accounts = [Account(id: "checking", label: "DEMO CHECKING (...7264)", cents: 248_670), Account(id: "savings", label: "DEMO SAVINGS (...8391)", cents: 612_540)]
    public static let recipients = [
        Recipient(id: "jordan", name: "Jordan Ellis", contact: "(202) 555-0146"),
        Recipient(id: "riley", name: "Riley Chen", contact: "(202) 555-0112"),
        Recipient(id: "club", name: "MAPLE COMMUNITY ARTS COLLECTIVE, NORTH CHAPTER", contact: "maple.arts@example.com"),
        Recipient(id: "taylor", name: "Taylor Morgan", contact: "(202) 555-0168"),
        Recipient(id: "casey", name: "Casey Brooks", contact: "casey.brooks@example.com"),
        Recipient(id: "morgan", name: "Morgan Reed", contact: "(202) 555-0183"),
        Recipient(id: "sam", name: "Sam Rivera", contact: "(202) 555-0194"),
        Recipient(id: "alex", name: "Alexandra Bennett", contact: "alex.bennett@example.com"),
        Recipient(id: "devon", name: "Devon Parker", contact: "(202) 555-0109")]
    public static func money(_ cents: Int) -> String { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"; f.locale = Locale(identifier: "en_US"); return f.string(from: NSNumber(value: Double(cents) / 100))! }
    public static func day(_ date: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.timeZone = calendar.timeZone; f.dateFormat = "MMM d, yyyy"; return f.string(from: date) }
    public static func cents(_ text: String) -> Int? {
        guard text.range(of: #"^\d{1,7}(\.\d{0,2})?$"#, options: .regularExpression) != nil else { return nil }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard let dollars = Int(parts[0]) else { return nil }
        let fractional = parts.count > 1 ? String(parts[1]) : ""
        return dollars * 100 + (Int(fractional.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0)
    }
    public static func filter(_ recipients: [Recipient], query: String) -> [Recipient] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return recipients }
        let digits = q.filter(\.isNumber)
        return recipients.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.contact.localizedCaseInsensitiveContains(q) || (!digits.isEmpty && q.allSatisfy { $0.isNumber || " ()-+.".contains($0) } && $0.contact.filter(\.isNumber).contains(digits)) }
    }
    public static func validContact(_ value: String) -> Bool {
        let digits = value.filter(\.isNumber)
        let phone = digits.count == 10 && digits.hasPrefix("20255501") && value.allSatisfy { $0.isNumber || " ()-+.".contains($0) }
        let email = value.range(of: #"^[A-Za-z0-9._%+\-]+@example\.com$"#, options: .regularExpression) != nil
        return phone || email
    }
}
public struct Ledger: Codable, Sendable {
    public var accounts = Demo.accounts
    public private(set) var payments: [Payment] = []
    public init() {}
    public func validate(_ draft: Draft, now: Date = Demo.today) throws -> Int {
        guard let cents = Demo.cents(draft.amount), cents > 0 else { throw PaymentError.invalid }
        guard cents <= Demo.limit else { throw PaymentError.limit }
        guard let account = accounts.first(where: { $0.id == draft.accountID }) else { throw PaymentError.account }
        guard cents <= account.cents else { throw PaymentError.balance }
        guard Demo.calendar.startOfDay(for: draft.date) >= Demo.calendar.startOfDay(for: now) else { throw PaymentError.date }
        guard draft.message.count <= 140 else { throw PaymentError.message }
        return cents
    }
    @discardableResult public mutating func submit(_ draft: Draft, id: UUID, now: Date = Demo.today) throws -> Payment {
        guard !payments.contains(where: { $0.id == id }) else { throw PaymentError.duplicate }
        let cents = try validate(draft, now: now)
        let index = accounts.firstIndex(where: { $0.id == draft.accountID })!
        let scheduled = Demo.calendar.startOfDay(for: draft.date) > Demo.calendar.startOfDay(for: now)
        let payment = Payment(id: id, recipient: draft.recipient, cents: cents, message: draft.message, account: accounts[index], date: draft.date, frequency: draft.frequency, scheduled: scheduled, sender: Demo.sender)
        if !scheduled { accounts[index].cents -= cents }
        payments.insert(payment, at: 0)
        return payment
    }
}
