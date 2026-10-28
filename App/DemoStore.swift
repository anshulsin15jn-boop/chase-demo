import SwiftUI
import DemoCore

enum RootTab: String, CaseIterable {
    case accounts = "Accounts", pay = "Pay & transfer", plan = "Plan & track", more = "More"
    var icon: String { switch self { case .accounts: "wallet.bifold"; case .pay: "arrow.triangle.2.circlepath.circle"; case .plan: "list.clipboard"; case .more: "line.3.horizontal" } }
}
enum Route: Hashable { case directory, search, amount, review, confirmation }
enum DemoSheet: String, Identifiable {
    case information, add, qr, account, date, frequency, activity, profile
    var id: String { rawValue }
}
@MainActor @Observable final class DemoStore {
    var state = LocalState()
    var tab: RootTab = .accounts
    var path: [Route] = []
    var draft: Draft?
    var submitted: Payment?
    var submissionID = UUID()
    var isSubmitting = false
    var sheet: DemoSheet?
    var infoTitle = "Independent hackathon simulation"
    var infoText = "This feature is local to your device. No real banking service is connected."
    var directoryDue = false
    var error: String?
    var amountError: String?
    var onboardingError: String?
    var discard = false
    var now: Date
    var calendar: Calendar
    private var baseline: Draft?
    @ObservationIgnored private let repository: LocalPersistence?
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private let calendarProvider: () -> Calendar
    private var persistenceBlocked = false

    init(repository: LocalPersistence? = LocalPersistence(), clock: @escaping () -> Date = Date.init,
         calendarProvider: @escaping () -> Calendar = { .autoupdatingCurrent }, initialState: LocalState? = nil) {
        self.repository = repository; self.clock = clock; self.calendarProvider = calendarProvider
        now = clock(); calendar = calendarProvider()
        if let initialState { state = initialState }
        else if let repository {
            do { state = try repository.load() }
            catch { persistenceBlocked = true; self.error = "Saved demo data could not be read. It has been left untouched. Reset the demo only if you want to replace it." }
        }
    }
    var recipients: [Recipient] { state.recipients }
    var ledger: Ledger { state.ledger }
    var firstName: String { state.profile?.firstName ?? "" }
    var fullName: String { state.profile?.fullName ?? "" }
    var senderIdentity: String { fullName.uppercased() }
    var needsFirstName: Bool { state.profile?.isComplete != true }
    var meaningful: Bool { guard let draft else { return false }; return draft != baseline }
    func accountLabel(_ account: Account) -> String { account.displayLabel(firstName: fullName) }
    func dateLabel(_ date: Date) -> String { LocalDay.label(date, now: now, calendar: calendar) }
    func dateLabel(_ payment: Payment) -> String { LocalDay.recordLabel(payment, now: now, calendar: calendar) }
    private func save(_ candidate: LocalState) throws {
        guard !persistenceBlocked else { throw InputError.firstName }
        try repository?.save(candidate)
    }
    func completeOnboarding(_ value: String, lastName: String, middleName: String = "") {
        do {
            var candidate = state; try candidate.onboard(firstName: value, lastName: lastName, middleName: middleName); try save(candidate)
            state = candidate; onboardingError = nil
        } catch let issue as InputError { onboardingError = persistenceBlocked ? "Existing local data is unavailable. It has not been overwritten." : issue.rawValue }
        catch { onboardingError = "Your name could not be saved locally. Please try again." }
    }
    func updateProfile(firstName: String, lastName: String, middleName: String) throws {
        var candidate = state
        try candidate.onboard(firstName: firstName, lastName: lastName, middleName: middleName)
        try save(candidate); state = candidate
    }
    func addRecipient(name: String, number: String, email: String) throws {
        var candidate = state
        try candidate.addRecipient(name: name, number: number, email: email)
        try save(candidate); state = candidate
    }
    func refreshDay() {
        now = clock(); calendar = calendarProvider()
        draft?.refresh(now: now, calendar: calendar)
        baseline?.refresh(now: now, calendar: calendar)
    }
    func selectDate(_ value: Date) { draft?.selectDate(value, calendar: calendar) }
    func selectToday() { refreshDay(); draft?.selectToday(now: now, calendar: calendar) }
    func select(_ recipient: Recipient) {
        refreshDay()
        if draft?.recipient.id != recipient.id {
            let value = Draft(recipient: recipient, now: now, calendar: calendar)
            draft = value; baseline = value; submissionID = UUID(); submitted = nil; amountError = nil
        }
        // Publish one complete destination path instead of two observable mutations.
        path = path.filter { $0 != .search && $0 != .amount && $0 != .review } + [.amount]
    }
    func directory(due: Bool = false) { directoryDue = due; path = [.directory] }
    func explain(_ title: String, _ body: String = "This is an independent hackathon simulation. No real account, contact discovery, device service, or payment is accessed.") { infoTitle = title; infoText = body; sheet = .information }
    func cancel() { if meaningful { discard = true } else { clearDraft() } }
    func clearDraft() { discard = false; draft = nil; baseline = nil; submitted = nil; amountError = nil; submissionID = UUID(); path = [.directory] }
    func done() { draft = nil; baseline = nil; submitted = nil; amountError = nil; submissionID = UUID(); path = []; tab = .pay }
    private func present(_ issue: Error) {
        if let issue = issue as? PaymentError, [.invalid, .limit, .balance].contains(issue) { amountError = issue.rawValue }
        else { error = (issue as? PaymentError)?.rawValue ?? "Please check the payment details." }
    }
    func review() {
        refreshDay(); guard let draft, !needsFirstName else { return }
        do { _ = try ledger.validate(draft, now: now, calendar: calendar); amountError = nil; path.append(.review) }
        catch { present(error) }
    }
    func send() async {
        guard !isSubmitting, submitted == nil, !needsFirstName else { return }
        isSubmitting = true; defer { isSubmitting = false }
        do {
            try await Task.sleep(for: .milliseconds(650))
            refreshDay(); guard let draft else { return }
            var candidate = state
            let payment = try candidate.ledger.submit(draft, id: submissionID, sender: fullName, now: now, calendar: calendar)
            try save(candidate); state = candidate; submitted = payment; path = [.confirmation]
        } catch { present(error) }
    }
    func reset() {
        var candidate = state; candidate.resetDemo()
        persistenceBlocked = false
        do { try save(candidate); state = candidate; draft = nil; baseline = nil; submitted = nil; amountError = nil; path = []; tab = .accounts }
        catch { self.error = "The local demo could not be reset." }
    }
}
