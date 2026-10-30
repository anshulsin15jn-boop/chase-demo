#if DEBUG
import Foundation
import DemoCore

// Deterministic, synthetic state is available only in debug builds used by CI.
@MainActor enum DemoHarness {
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    static var date: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 12))! }
    static func makeStore(arguments: [String]) -> DemoStore? {
        guard arguments.contains("--ui-testing") || arguments.contains("--demo-screen") else { return nil }
        var repository: LocalPersistence?
        if let i = arguments.firstIndex(of: "--persistent-suite"), arguments.indices.contains(i + 1),
           let defaults = UserDefaults(suiteName: "io.hackathon.fictionalbank.uitest." + arguments[i + 1]) {
            repository = LocalPersistence(defaults: defaults)
            if arguments.contains("--seed-legacy"), defaults.data(forKey: LocalPersistence.storageKey) == nil {
                var state = LocalState(accountsInitialized: true)
                let earlier = calendar.date(byAdding: .day, value: -3, to: date)!
                var draft = Draft(recipient: Demo.recipients[0], now: earlier, calendar: calendar)
                draft.amount = try! CurrencyInput(digits: "1250")
                try! state.ledger.submit(draft, id: UUID(), sender: "Avery", now: earlier, calendar: calendar)
                let local = Recipient(id: "legacy-local", name: "Jamie Vale", phoneDigits: "2025550155")
                state.recipients.append(local)
                var object = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
                object["profile"] = ["firstName": "Avery"]
                object.removeValue(forKey: "accountsInitialized"); object.removeValue(forKey: "startingAccounts")
                object["recipients"] = state.recipients.map { ["id": $0.id, "name": $0.name, "contact": $0.contact] }
                defaults.set(try! JSONSerialization.data(withJSONObject: object), forKey: LocalPersistence.storageKey)
            }
        }
        let store = DemoStore(repository: repository, clock: { date }, calendarProvider: { calendar }, initialState: repository == nil ? LocalState(accountsInitialized: true) : nil)
        if let i = arguments.firstIndex(of: "--demo-screen"), arguments.indices.contains(i + 1) { preview(arguments[i + 1], store: store) }
        return store
    }
    static func preview(_ screen: String, store: DemoStore) {
        if screen == "onboarding" { return }
        store.completeOnboarding("Avery", lastName: "Collins")
        switch screen {
        case "account-details", "transactions":
            for (index, recipient) in Demo.recipients.prefix(2).enumerated() {
                var draft = Draft(recipient: recipient, now: date, calendar: calendar)
                draft.amount = try! CurrencyInput(digits: "100")
                _ = try! store.state.ledger.submit(draft, id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!, sender: store.fullName, now: date, calendar: calendar)
            }
            store.path = screen == "transactions" ? [.accountDetails, .transactions] : [.accountDetails]
        case "profile": store.sheet = .profile
        case "amount-created", "confirmation-created", "confirmation-long", "confirmation-number":
            let name = screen == "confirmation-number" ? "" : screen == "confirmation-long" ? "Alexandra-Marie O'Neil Rivera Bennett" : "Jamie Vale"
            let recipient = try! store.state.addRecipient(name: name, number: "2025550158")
            store.select(recipient)
            if screen != "amount-created", let original = store.draft {
                var draft = original; draft.amount = try! CurrencyInput(digits: "500")
                store.submitted = try! store.state.ledger.submit(draft, id: store.submissionID, sender: store.fullName, now: date, calendar: calendar)
                store.path = [.confirmation]
            }
        case "hub": store.tab = .pay
        case "directory": store.path = [.directory]
        case "search": store.path = [.directory, .search]
        case "add": store.path = [.directory]; store.sheet = .add
        case "amount", "amount-error", "review", "confirmation":
            store.select(store.recipients[0])
            if screen == "amount-error" { store.review() }
            if screen == "review" || screen == "confirmation" {
                store.draft?.amount = try! CurrencyInput(digits: "2450"); store.draft?.message = "Demo lunch"
                store.selectDate(calendar.date(byAdding: .day, value: 2, to: date)!)
                if screen == "review" { store.path = [.directory, .amount, .review] }
                else if let draft = store.draft {
                    store.submitted = try! store.state.ledger.submit(draft, id: store.submissionID, sender: store.fullName, now: date, calendar: calendar)
                    store.path = [.confirmation]
                }
            }
        default: break
        }
    }
}
#endif
