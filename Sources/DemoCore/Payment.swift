import Foundation

public enum InputError: String, Error {
    case firstName = "Please enter your first name."
    case emptyRecipient = "Enter a name, a 9 or 10 digit number, or an email address."
    case phone = "Enter 9 or 10 digits using 0–9 only."
    case email = "Enter a valid email address, or leave email empty."
    case duplicateRecipient = "This recipient is already saved."
    case digits = "Use digits 0–9 only."
    case overflow = "This amount is too large."
}
public struct LocalProfile: Codable, Equatable, Sendable {
    public let firstName: String
    public init(firstName: String) throws {
        let value = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw InputError.firstName }
        self.firstName = value
    }
}
public enum PhoneNumber {
    public static func isASCII(_ value: String) -> Bool { value.utf8.allSatisfy { (48...57).contains($0) } }
    public static func validate(_ value: String) throws -> String {
        let digits = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard [9, 10].contains(digits.count), isASCII(digits) else { throw InputError.phone }
        return digits
    }
    public static func display(_ digits: String) -> String {
        guard isASCII(digits) else { return digits }
        let c = Array(digits)
        if c.count == 9 { return "\(String(c[0..<3]))-\(String(c[3..<6]))-\(String(c[6..<9]))" }
        if c.count == 10 { return "(\(String(c[0..<3]))) \(String(c[3..<6]))-\(String(c[6..<10]))" }
        return digits
    }
}
public struct Recipient: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let phoneDigits: String
    public let email: String
    public let registered: Bool
    public var displayName: String { !name.isEmpty ? name : (!phoneDigits.isEmpty ? PhoneNumber.display(phoneDigits) : email) }
    public var contact: String { !phoneDigits.isEmpty ? PhoneNumber.display(phoneDigits) : email }
    public var subtitle: String { !name.isEmpty ? contact : (!phoneDigits.isEmpty ? email : "") }
    public var initial: String { name.split(whereSeparator: \.isWhitespace).prefix(2).map { String($0.prefix(1)) }.joined().uppercased() }
    public init(id: String, name: String, phoneDigits: String = "", email: String = "", registered: Bool = false) {
        self.id = id; self.name = name; self.phoneDigits = phoneDigits; self.email = email; self.registered = registered
    }
    public static func create(name: String, number: String, email: String = "", id: String = UUID().uuidString) throws -> Recipient {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty || !p.isEmpty || !e.isEmpty else { throw InputError.emptyRecipient }
        let phone: String
        if p.isEmpty { phone = "" } else { phone = try PhoneNumber.validate(p) }
        if !e.isEmpty, e.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) == nil { throw InputError.email }
        return Recipient(id: id, name: n, phoneDigits: phone, email: e)
    }
    enum CodingKeys: String, CodingKey { case id, name, contact, phoneDigits, email, registered }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = (try c.decodeIfPresent(String.self, forKey: .name) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let legacy = try c.decodeIfPresent(String.self, forKey: .contact) ?? ""
        let oldDigits = legacy.utf8.filter { (48...57).contains($0) }
        phoneDigits = try c.decodeIfPresent(String.self, forKey: .phoneDigits) ?? (legacy.contains("@") ? "" : String(decoding: oldDigits, as: UTF8.self))
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? (legacy.contains("@") ? legacy : "")
        registered = try c.decodeIfPresent(Bool.self, forKey: .registered) ?? ["jordan", "riley", "club", "taylor", "casey", "morgan", "sam", "alex", "devon"].contains(id)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(phoneDigits, forKey: .phoneDigits); try c.encode(email, forKey: .email); try c.encode(registered, forKey: .registered)
    }
}
public struct Account: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    // Retained for decoding old snapshots. Visible labels derive from the device's local profile.
    public let label: String
    public var cents: Int
    public var type: String { id == "savings" ? "SAVINGS" : "CHECKING" }
    public init(id: String, label: String, cents: Int) { self.id = id; self.label = label; self.cents = cents }
    public func displayLabel(firstName: String) -> String { "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()) \(type) (..5020)" }
}
public struct CurrencyInput: Equatable, Codable, Sendable {
    public private(set) var digits = ""
    public private(set) var cents = 0
    public init() {}
    public init(digits: String) throws { try replace(with: digits) }
    public mutating func replace(with text: String) throws {
        guard PhoneNumber.isASCII(text) else { throw InputError.digits }
        guard text.count <= 19 else { throw InputError.overflow }
        var amount = 0
        for byte in text.utf8 {
            let (multiplied, over1) = amount.multipliedReportingOverflow(by: 10)
            let (added, over2) = multiplied.addingReportingOverflow(Int(byte - 48))
            guard !over1, !over2 else { throw InputError.overflow }
            amount = added
        }
        digits = text; cents = amount
    }
    public mutating func append(_ text: String) throws { try replace(with: digits + text) }
    public mutating func backspace() { if !digits.isEmpty { try? replace(with: String(digits.dropLast())) } }
    public var formatted: String { Demo.money(cents) }
}
public enum LocalDay {
    public static func label(_ date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.calendar = calendar; f.timeZone = calendar.timeZone; f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
public enum Frequency: String, CaseIterable, Codable, Sendable { case once = "Once", weekly = "Weekly", monthly = "Monthly" }
public struct Draft: Equatable, Sendable {
    public var recipient: Recipient
    public var amount = CurrencyInput()
    public var message = ""
    public var accountID = "checking"
    public private(set) var date: Date
    public private(set) var usesToday = true
    public var frequency: Frequency = .once
    public init(recipient: Recipient, now: Date, calendar: Calendar) { self.recipient = recipient; date = calendar.startOfDay(for: now) }
    public mutating func selectDate(_ value: Date) { date = value; usesToday = false }
    public mutating func selectToday(now: Date, calendar: Calendar) { usesToday = true; date = calendar.startOfDay(for: now) }
    public mutating func refresh(now: Date, calendar: Calendar) { if usesToday { date = calendar.startOfDay(for: now) } }
    public func effectiveDate(now: Date, calendar: Calendar) -> Date { usesToday ? calendar.startOfDay(for: now) : date }
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
public enum PaymentError: String, Error {
    case invalid = "Please tell us an amount."
    case limit = "This amount exceeds the $10,000.00 demo limit."
    case balance = "This amount exceeds your available demo balance."
    case date = "This payment date is in the past. Please choose Today or a future date."
    case message = "Messages can contain up to 140 characters."
    case duplicate = "This payment has already been submitted."
    case account = "Choose a demo account."
}
public enum Demo {
    public static let limit = 1_000_000
    public static let accounts = [Account(id: "checking", label: "CHECKING (..5020)", cents: 248_670), Account(id: "savings", label: "SAVINGS (..5020)", cents: 612_540)]
    public static let recipients = [
        Recipient(id: "jordan", name: "Jordan Ellis", phoneDigits: "2025550146", registered: true),
        Recipient(id: "riley", name: "Riley Chen", phoneDigits: "2025550112", registered: true),
        Recipient(id: "club", name: "MAPLE DELTA ARTS CLUB - NORTH CHAPTER, DEMO CITY", email: "maple@example.com", registered: true),
        Recipient(id: "taylor", name: "Taylor Morgan", phoneDigits: "2025550168", registered: true),
        Recipient(id: "casey", name: "Casey Brooks", email: "casey.brooks@example.com", registered: true),
        Recipient(id: "morgan", name: "Morgan Reed", phoneDigits: "2025550183", registered: true),
        Recipient(id: "sam", name: "Sam Rivera", phoneDigits: "2025550194", registered: true),
        Recipient(id: "alex", name: "Alexandra Bennett", email: "alex.bennett@example.com", registered: true),
        Recipient(id: "devon", name: "Devon Parker", phoneDigits: "2025550109", registered: true)]
    public static func money(_ cents: Int) -> String {
        let dollars = String(cents / 100)
        let grouped = dollars.reversed().enumerated().map { index, char in String(char) + (index > 0 && index % 3 == 0 ? "," : "") }.reversed().joined()
        let fraction = String(cents % 100)
        return "$" + grouped + "." + (fraction.count == 1 ? "0" : "") + fraction
    }
    public static func filter(_ recipients: [Recipient], query: String) -> [Recipient] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return recipients }
        let digits = String(decoding: q.utf8.filter { (48...57).contains($0) }, as: UTF8.self)
        return recipients.filter { $0.displayName.localizedCaseInsensitiveContains(q) || $0.email.localizedCaseInsensitiveContains(q) || (!digits.isEmpty && q.allSatisfy { $0.isNumber || " ()-+.".contains($0) } && $0.phoneDigits.contains(digits)) }
    }
}
public struct Ledger: Codable, Sendable {
    public var accounts = Demo.accounts
    public private(set) var payments: [Payment] = []
    public init() {}
    public func validate(_ draft: Draft, now: Date, calendar: Calendar) throws -> Int {
        let cents = draft.amount.cents
        guard cents > 0 else { throw PaymentError.invalid }
        guard cents <= Demo.limit else { throw PaymentError.limit }
        guard let account = accounts.first(where: { $0.id == draft.accountID }) else { throw PaymentError.account }
        guard cents <= account.cents else { throw PaymentError.balance }
        guard calendar.startOfDay(for: draft.effectiveDate(now: now, calendar: calendar)) >= calendar.startOfDay(for: now) else { throw PaymentError.date }
        guard draft.message.count <= 140 else { throw PaymentError.message }
        return cents
    }
    @discardableResult public mutating func submit(_ draft: Draft, id: UUID, sender: String, now: Date, calendar: Calendar) throws -> Payment {
        guard !payments.contains(where: { $0.id == id }) else { throw PaymentError.duplicate }
        let profile = try LocalProfile(firstName: sender)
        let cents = try validate(draft, now: now, calendar: calendar)
        let index = accounts.firstIndex(where: { $0.id == draft.accountID })!
        let date = draft.effectiveDate(now: now, calendar: calendar)
        let scheduled = calendar.startOfDay(for: date) > calendar.startOfDay(for: now)
        let payment = Payment(id: id, recipient: draft.recipient, cents: cents, message: draft.message, account: accounts[index], date: date, frequency: draft.frequency, scheduled: scheduled, sender: profile.firstName)
        if !scheduled { accounts[index].cents -= cents }
        payments.insert(payment, at: 0)
        return payment
    }
}
public struct LocalState: Codable, Sendable {
    public var ledger = Ledger()
    public var recipients = Demo.recipients
    public var profile: LocalProfile?
    public init() {}
    public mutating func onboard(firstName: String) throws { profile = try LocalProfile(firstName: firstName) }
    @discardableResult public mutating func addRecipient(name: String, number: String, email: String = "") throws -> Recipient {
        let value = try Recipient.create(name: name, number: number, email: email)
        guard !recipients.contains(where: {
            (!value.phoneDigits.isEmpty && $0.phoneDigits == value.phoneDigits) ||
            (!value.email.isEmpty && $0.email.caseInsensitiveCompare(value.email) == .orderedSame) ||
            (value.phoneDigits.isEmpty && value.email.isEmpty && $0.name.caseInsensitiveCompare(value.name) == .orderedSame)
        }) else { throw InputError.duplicateRecipient }
        recipients.insert(value, at: 0); return value
    }
}
public final class LocalPersistence {
    public static let storageKey = "fictional-demo-state-v1"
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func load() throws -> LocalState {
        guard let data = defaults.data(forKey: Self.storageKey) else { return LocalState() }
        return try JSONDecoder().decode(LocalState.self, from: data)
    }
    public func save(_ state: LocalState) throws { defaults.set(try JSONEncoder().encode(state), forKey: Self.storageKey) }
}
