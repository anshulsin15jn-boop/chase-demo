import SwiftUI
import DemoCore

enum RootTab: String, CaseIterable { case accounts = "Accounts", pay = "Pay & transfer", plan = "Plan & track", more = "More"
    var icon: String { switch self { case .accounts: "wallet.bifold"; case .pay: "arrow.triangle.2.circlepath.circle"; case .plan: "list.clipboard"; case .more: "line.3.horizontal" } }
}
enum Route: Hashable { case directory, search, amount, review, confirmation }
enum DemoSheet: String, Identifiable { case information, add, qr, account, date, frequency, activity
    var id: String { rawValue }
}
@MainActor @Observable final class DemoStore {
    var tab: RootTab = .accounts
    var path: [Route] = []
    var recipients = Demo.recipients
    var ledger = Ledger()
    var draft: Draft?
    var submitted: Payment?
    var submissionID = UUID()
    var isSubmitting = false
    var showWelcome = true
    var sheet: DemoSheet?
    var infoTitle = "Hackathon demonstration"
    var infoText = "This feature is a local demonstration. No banking service is connected."
    var directoryDue = false
    var error: String?
    var discard = false
    let now: Date
    private var baseline: Draft?
    private let storageKey = "fictional-demo-state-v1"
    private let persists: Bool
    struct Saved: Codable { let ledger: Ledger; let recipients: [Recipient] }
    init(persists: Bool = true, now: Date = Demo.today) {
        self.persists = persists; self.now = now
        if persists, let data = UserDefaults.standard.data(forKey: storageKey), let saved = try? JSONDecoder().decode(Saved.self, from: data) { ledger = saved.ledger; recipients = saved.recipients }
    }
    var meaningful: Bool { guard let draft else { return false }; return draft != baseline }
    func persist() { if persists, let data = try? JSONEncoder().encode(Saved(ledger: ledger, recipients: recipients)) { UserDefaults.standard.set(data, forKey: storageKey) } }
    func select(_ recipient: Recipient) {
        if draft?.recipient.id != recipient.id { let d = Draft(recipient: recipient, date: now); draft = d; baseline = d; submissionID = UUID(); submitted = nil }
        path.removeAll(where: { $0 == .search || $0 == .amount || $0 == .review }); path.append(.amount)
    }
    func directory(due: Bool = false) { directoryDue = due; path = [.directory] }
    func explain(_ title: String, _ body: String = "This is an offline hackathon simulation. No real account, recipient, device service, or payment is accessed.") { infoTitle = title; infoText = body; sheet = .information }
    func cancel() { if meaningful { discard = true } else { clearDraft() } }
    func clearDraft() { draft = nil; baseline = nil; submitted = nil; submissionID = UUID(); path = [.directory] }
    func done() { draft = nil; baseline = nil; submitted = nil; submissionID = UUID(); path = []; tab = .pay }
    func review() { guard let draft else { return }; do { _ = try ledger.validate(draft, now: now); path.append(.review) } catch { self.error = (error as? PaymentError)?.rawValue ?? "Check the payment details." } }
    func send() async {
        guard !isSubmitting, submitted == nil, let draft else { return }
        isSubmitting = true; defer { isSubmitting = false }
        do { try await Task.sleep(for: .milliseconds(650)); submitted = try ledger.submit(draft, id: submissionID, now: now); persist(); path = [.confirmation] }
        catch { self.error = (error as? PaymentError)?.rawValue ?? "Submission was interrupted. Please try again." }
    }
    func reset() { ledger = Ledger(); recipients = Demo.recipients; draft = nil; baseline = nil; submitted = nil; path = []; tab = .accounts; persist() }
    func preview(_ screen: String) {
        showWelcome = false
        switch screen {
        case "hub": tab = .pay
        case "directory": path = [.directory]
        case "search": path = [.directory, .search]
        case "amount", "review", "confirmation":
            select(recipients[0]); draft?.amount = "24.50"; draft?.message = "Demo lunch"; draft?.date = Demo.calendar.date(byAdding: .day, value: 2, to: now)!
            if screen == "review" { path = [.directory, .amount, .review] }
            if screen == "confirmation", let draft { submitted = try? ledger.submit(draft, id: submissionID); path = [.confirmation] }
        default: break
        }
    }
}
