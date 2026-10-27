import SwiftUI
import DemoCore
struct EnterAmountView: View {
    @Environment(DemoStore.self) private var store
    @FocusState private var input: Input?
    enum Input { case amount, message }
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Enter Amount", back: { input = nil; store.path.removeLast() }, cancel: { input = nil; store.cancel() })
            if let draft = store.draft {
                ScrollView { VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) { Identity(recipient: draft.recipient); Button { store.explain("Recipient details", "This recipient is fictional and registered for demonstration purposes only.") } label: { Image(systemName: "list.bullet.rectangle").font(.system(size: 22)) } }.padding(.top, 36).padding(.bottom, 28)
                    Text("Amount").font(.system(size: 14)).foregroundStyle(Style.gray).frame(maxWidth: .infinity)
                    HStack(spacing: 0) { Text("$"); TextField("0.00", text: bind(\.amount)).keyboardType(.decimalPad).focused($input, equals: .amount).fixedSize().accessibilityIdentifier("amount-field") }.font(.system(size: 42, weight: .light)).frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 4)
                    Rectangle().fill(Style.gray.opacity(0.7)).frame(height: 1)
                    Text("Today's limit for this recipient is $10,000.00.").font(.system(size: 11)).foregroundStyle(Style.gray).frame(maxWidth: .infinity).padding(.top, 8)
                    Button { store.explain("Demo payment limit", "Each simulated payment must be positive, no more than $10,000.00, and within the selected account's fictional available balance.") } label: { HStack(spacing: 5) { Text("Learn more"); Image(systemName: "chevron.right") }.font(.system(size: 13)).frame(maxWidth: .infinity).padding(.top, 7) }
                    Text("Message to recipient").font(.system(size: 14)).foregroundStyle(Style.gray).padding(.top, 20)
                    TextField("What's this for?", text: bind(\.message)).font(.system(size: 16)).focused($input, equals: .message).accessibilityIdentifier("message-field").onChange(of: store.draft?.message) { _, value in if let value, value.count > 140 { store.draft?.message = String(value.prefix(140)) } }.padding(.vertical, 6)
                    Rectangle().fill(Style.gray.opacity(0.7)).frame(height: 1)
                    Text("\(140 - draft.message.count) of 140 characters remaining.").font(.system(size: 11)).foregroundStyle(Style.gray).padding(.top, 4)
                    Button { input = nil; store.sheet = .account } label: { VStack(alignment: .leading, spacing: 5) { Text("Pay from").font(.system(size: 13)).foregroundStyle(Style.gray); HStack { Text(store.ledger.accounts.first(where: { $0.id == draft.accountID })?.label ?? "Choose account").font(.system(size: 14)); Spacer(minLength: 2); Text(Demo.money(store.ledger.accounts.first(where: { $0.id == draft.accountID })?.cents ?? 0)).font(.system(size: 13)); Image(systemName: "chevron.down") }.foregroundStyle(Style.gray) }.padding(.vertical, 12).overlay(alignment: .bottom) { Divider() } }.padding(.top, 30).accessibilityIdentifier("account-picker")
                    Button { input = nil; store.sheet = .date } label: { HStack { VStack(alignment: .leading, spacing: 9) { Text("Send on").font(.system(size: 13)).foregroundStyle(Style.gray); Text(Demo.day(draft.date)).font(.system(size: 16)) }; Spacer(); Image(systemName: "calendar").font(.system(size: 21)).foregroundStyle(Style.gray) }.padding(.vertical, 21).overlay(alignment: .bottom) { Rectangle().fill(Style.gray.opacity(0.7)).frame(height: 1) } }.accessibilityIdentifier("date-picker")
                    Button("Delivery time and sending limits ?") { store.explain("Delivery time and sending limits", "All transfers are local simulations. Future demo dates are recorded as scheduled and do not reduce available balances. Repeating payments save the chosen frequency without executing future transfers.") }.font(.system(size: 13)).padding(.top, 36)
                    Toggle("Repeat payment", isOn: Binding(get: { draft.frequency != .once }, set: { enabled in input = nil; if enabled { store.draft?.frequency = .weekly; store.sheet = .frequency } else { store.draft?.frequency = .once } })).font(.system(size: 16)).foregroundStyle(Style.gray).tint(Style.blue).padding(.top, 24).accessibilityIdentifier("repeat-toggle")
                    if draft.frequency != .once { Button("Frequency: \(draft.frequency.rawValue)") { store.sheet = .frequency }.font(.footnote).padding(.top, 8) }
                    PrimaryButton(title: "Review & send") { input = nil; store.review() }.accessibilityIdentifier("review-send").padding(.top, 34).padding(.bottom, 26)
                }.padding(.horizontal, 20) }.scrollDismissesKeyboard(.interactively)
            }
        }.background(.white).toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { input = nil } } }
    }
    private func bind(_ keyPath: WritableKeyPath<Draft, String>) -> Binding<String> { Binding(get: { store.draft?[keyPath: keyPath] ?? "" }, set: { store.draft?[keyPath: keyPath] = $0 }) }
}
struct ReviewPaymentView: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Review", back: { if !store.isSubmitting { store.path.removeLast() } }, cancel: { if !store.isSubmitting { store.cancel() } }).disabled(store.isSubmitting)
            if let d = store.draft {
                ScrollView { VStack(spacing: 0) {
                    Identity(recipient: d.recipient, centered: true).padding(.top, 22)
                    Text("Amount").font(.system(size: 12)).padding(.top, 16)
                    Text(Demo.money(Demo.cents(d.amount) ?? 0)).font(.system(size: 36)).padding(.top, 8).padding(.bottom, 28)
                    Rectangle().fill(Style.background).frame(height: 14)
                    VStack(spacing: 25) { detail("Sending as", Demo.sender); detail("Pay from", store.ledger.accounts.first(where: { $0.id == d.accountID })?.label ?? ""); detail("Send on", Demo.day(d.date)); detail("Message to recipient", d.message.isEmpty ? "No message" : d.message); if d.frequency != .once { detail("Repeat payment", d.frequency.rawValue) } }.padding(.horizontal, 20).padding(.top, 14)
                } }
                VStack(alignment: .leading, spacing: 12) { Text("Only send money to people and businesses you trust. Zelle? doesn't offer protection for payments you authorize, so you might not be able to get your money back once you send it.").font(.system(size: 13)).foregroundStyle(Style.gray); PrimaryButton(title: store.isSubmitting ? "Sending demo payment?" : "Send it now", loading: store.isSubmitting) { Task { await store.send() } }.accessibilityIdentifier("send-now") }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 26)
            }
        }.background(.white).interactiveDismissDisabled(store.isSubmitting)
    }
    func detail(_ title: String, _ value: String) -> some View { HStack(alignment: .top) { Text(title); Spacer(minLength: 24); Text(value).multilineTextAlignment(.trailing) }.font(.system(size: 13)) }
}
struct ConfirmationView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var check = false
    @State private var content = false
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Confirmation")
            if let p = store.submitted {
                ScrollView { VStack(spacing: 0) {
                    Image(systemName: "checkmark").font(.system(size: 31, weight: .semibold)).foregroundStyle(.white).frame(width: 46, height: 46).background(Style.teal, in: Circle()).scaleEffect(check ? 1 : 0.6).opacity(check ? 1 : 0).padding(.top, 26).padding(.bottom, 24)
                    VStack(spacing: 0) {
                        Text(p.scheduled ? "We'll let \(p.recipient.name) know your payment is coming on \(Demo.day(p.date)). If they aren't registered with Zelle?, they'll receive an email or text letting them know how to register. We'll send your money after they complete their registration." : "Your demo payment to \(p.recipient.name) is complete. No real money moved and no notification was sent.").font(.system(size: 16)).multilineTextAlignment(.center).lineSpacing(3).accessibilityIdentifier("confirmation-text")
                        Text(Demo.money(p.cents)).font(.system(size: 36)).padding(.top, 27).padding(.bottom, 24).accessibilityIdentifier("confirmation-amount")
                        Avatar(recipient: p.recipient, size: 52)
                        Text(p.recipient.name).font(.system(size: 18)).padding(.top, 22)
                        Text("Registered as \(p.recipient.name)\n\(p.recipient.contact)").font(.system(size: 11)).multilineTextAlignment(.center).padding(.top, 3)
                        Text("Add a Siri shortcut, such as ?Pay \(p.recipient.name.components(separatedBy: " ")[0])? to save time when sending money.").font(.system(size: 13)).multilineTextAlignment(.center).padding(.top, 48)
                        Button { store.explain("Add to Siri", "This button demonstrates the shortcut interface only. No Siri integration or real transfer is created.") } label: { Label("Add to Siri", systemImage: "waveform.circle.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary).padding(.horizontal, 20).frame(height: 52).overlay(RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 0.6)) }.padding(.top, 18)
                    }.opacity(content ? 1 : 0)
                }.padding(.horizontal, 20).padding(.bottom, 20) }
                PrimaryButton(title: "Done") { store.done() }.accessibilityIdentifier("confirmation-done").padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 26)
            }
        }.background(.white).task { if reduceMotion { check = true; content = true } else { withAnimation(.spring(duration: 0.3)) { check = true }; try? await Task.sleep(for: .milliseconds(250)); withAnimation(.easeIn(duration: 0.28)) { content = true } } }
    }
}
