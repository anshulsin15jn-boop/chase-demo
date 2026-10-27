import SwiftUI
import UIKit
import DemoCore

struct EnterAmountView: View {
    @Environment(DemoStore.self) private var store
    @FocusState private var messageFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Enter Amount", back: { dismissKeyboard(); store.path.removeLast() }, cancel: { dismissKeyboard(); store.cancel() })
            if let draft = store.draft {
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Identity(recipient: draft.recipient)
                            Button { store.explain("Recipient details", "This recipient is stored locally. No registration lookup or contact discovery occurs.") } label: {
                                DocumentListGlyph().stroke(Style.blue, style: StrokeStyle(lineWidth: 1.35, lineCap: .square)).frame(width: 18, height: 24).frame(width: 28, height: 32, alignment: .topTrailing)
                            }.buttonStyle(.plain).accessibilityLabel("Recipient details")
                        }.padding(.top, 48).padding(.bottom, 28)
                        Text("Amount").font(.system(size: 14)).foregroundStyle(store.amountError == nil ? Style.gray : Style.error).frame(maxWidth: .infinity).id("amount-section")
                        CurrencyEntry(value: Binding(get: { store.draft?.amount ?? CurrencyInput() }, set: { store.draft?.amount = $0; store.amountError = nil }), invalidInput: { store.amountError = $0 })
                            .frame(height: 54).padding(.top, 4).padding(.bottom, 2)
                        Rectangle().fill(store.amountError == nil ? Style.gray.opacity(0.7) : Style.error).frame(height: 1)
                        if let error = store.amountError {
                            Label(error, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(Style.error)
                                .frame(maxWidth: .infinity).padding(.top, 6).accessibilityIdentifier("amount-error")
                        }
                        Text("Today's limit for this recipient is \(Demo.money(Demo.limit)).").font(.system(size: 11)).foregroundStyle(Style.gray).frame(maxWidth: .infinity).padding(.top, 7)
                        Button { store.explain("Demo payment limit", "Amounts must be positive, within the fictional account balance, and no more than the displayed demo limit.") } label: {
                            HStack(spacing: 5) { Text("Learn more"); Image(systemName: "chevron.right") }.font(.system(size: 13)).frame(maxWidth: .infinity).padding(.top, 7)
                        }
                        Text("Message to recipient").font(.system(size: 14)).foregroundStyle(Style.gray).padding(.top, 14)
                        TextField("What's this for?", text: Binding(get: { store.draft?.message ?? "" }, set: { store.draft?.message = $0 }), prompt: Text("What's this for?").foregroundStyle(Style.gray))
                            .font(.system(size: 16)).focused($messageFocused).accessibilityIdentifier("message-field")
                            .onChange(of: store.draft?.message) { _, value in
                                if let value, value.count > 140 { store.draft?.message = String(value.prefix(140)) }
                            }.padding(.vertical, 6)
                        Rectangle().fill(Style.gray.opacity(0.7)).frame(height: 1)
                        Text("\(140 - draft.message.count) of 140 characters remaining.").font(.system(size: 11)).foregroundStyle(Style.gray).padding(.top, 4)
                        Button { dismissKeyboard(); store.sheet = .account } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Pay from").font(.system(size: 13))
                                HStack(spacing: 5) {
                                    Text(store.ledger.accounts.first(where: { $0.id == draft.accountID }).map(store.accountLabel) ?? "Choose account").font(.system(size: 14)).lineLimit(1).minimumScaleFactor(0.75)
                                    Text(Demo.money(store.ledger.accounts.first(where: { $0.id == draft.accountID })?.cents ?? 0)).font(.system(size: 13))
                                    Spacer(minLength: 1); Image(systemName: "chevron.down")
                                }
                            }.foregroundStyle(Style.gray).padding(.vertical, 12).overlay(alignment: .bottom) { Rectangle().fill(Color(.systemGray4)).frame(height: 0.5) }
                        }.padding(.top, 26).accessibilityIdentifier("account-picker")
                        Button { dismissKeyboard(); store.refreshDay(); store.sheet = .date } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 9) { Text("Send on").font(.system(size: 13)).foregroundStyle(Style.gray); Text(store.dateLabel(draft.effectiveDate(now: store.now, calendar: store.calendar))).font(.system(size: 16)) }
                                Spacer(); CalendarGlyph().stroke(Style.gray, lineWidth: 1.2).frame(width: 18, height: 20)
                            }.padding(.top, 20).padding(.bottom, 12).overlay(alignment: .bottom) { Rectangle().fill(Style.gray.opacity(0.7)).frame(height: 1) }
                        }.accessibilityIdentifier("date-picker")
                        Button("Delivery time and sending limits ⓘ") { store.explain("Delivery time and sending limits", "Payments remain on this device. Future payments are recorded as scheduled without reducing the balance. Repeating payments record a frequency and do not execute automatically.") }.font(.system(size: 13)).padding(.top, 36)
                        Toggle("Repeat payment", isOn: Binding(get: { draft.frequency != .once }, set: { enabled in dismissKeyboard(); if enabled { store.draft?.frequency = .weekly; store.sheet = .frequency } else { store.draft?.frequency = .once } }))
                            .font(.system(size: 16)).foregroundStyle(Style.gray).tint(Style.blue).padding(.top, 20).accessibilityIdentifier("repeat-toggle")
                        if draft.frequency != .once { Button("Frequency: \(draft.frequency.rawValue)") { store.sheet = .frequency }.font(.footnote).padding(.top, 8) }
                        PrimaryButton(title: "Review & send") { dismissKeyboard(); store.review() }.accessibilityIdentifier("review-send").padding(.top, 20).padding(.bottom, 26)
                    }.padding(.horizontal, 20)
                }.scrollDismissesKeyboard(.interactively).onChange(of: store.amountError) { _, value in
                    if value != nil { withAnimation { proxy.scrollTo("amount-section", anchor: .center) } }
                }
                }
            }
        }.background(.white).toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { dismissKeyboard() }.accessibilityIdentifier("keyboard-done") } }
    }
    private func dismissKeyboard() { messageFocused = false; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}
struct ReviewPaymentView: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Review", back: { if !store.isSubmitting { store.path.removeLast() } }, cancel: { if !store.isSubmitting { store.cancel() } }).disabled(store.isSubmitting)
            if let draft = store.draft {
                ScrollView { VStack(spacing: 0) {
                    Identity(recipient: draft.recipient, centered: true).padding(.top, 22)
                    Text("Amount").font(.system(size: 12)).padding(.top, 16)
                    Text(Demo.money(draft.amount.cents)).font(.system(size: 36)).padding(.top, 8).padding(.bottom, 28).accessibilityIdentifier("review-amount")
                    Rectangle().fill(Style.background).frame(height: 14)
                    VStack(spacing: 25) {
                        detail("Sending as", store.firstName)
                        detail("Pay from", store.ledger.accounts.first(where: { $0.id == draft.accountID }).map(store.accountLabel) ?? "")
                        detail("Send on", store.dateLabel(draft.effectiveDate(now: store.now, calendar: store.calendar)))
                        detail("Message to recipient", draft.message.isEmpty ? "No message" : draft.message)
                        if draft.frequency != .once { detail("Repeat payment", draft.frequency.rawValue) }
                    }.padding(.horizontal, 20).padding(.top, 14)
                } }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Only send money to people and businesses you trust. Zelle® doesn't offer protection for payments you authorize, so you might not be able to get your money back once you send it.").font(.system(size: 13)).foregroundStyle(Style.gray)
                    PrimaryButton(title: store.isSubmitting ? "Sending demo payment…" : "Send it now", loading: store.isSubmitting) { Task { await store.send() } }.accessibilityIdentifier("send-now")
                }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 26)
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
            VStack(spacing: 3) {
                Text("Confirmation").font(.system(size: 18, weight: .semibold))
                Text("HACKATHON DEMO").font(.system(size: 12)).foregroundStyle(Style.gray)
            }.frame(maxWidth: .infinity).frame(height: 54).background(Style.background)
            if let payment = store.submitted {
                let copy = ConfirmationContent(payment: payment)
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image(systemName: "checkmark").font(.system(size: 29, weight: .semibold)).foregroundStyle(.white).frame(width: 44, height: 44).background(Style.teal, in: Circle()).scaleEffect(check ? 1 : 0.6).opacity(check ? 1 : 0).padding(.top, 24).padding(.bottom, 24)
                            VStack(spacing: 0) {
                                Text(copy.paragraph).font(.system(size: 16)).multilineTextAlignment(.center).lineSpacing(2).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("confirmation-text")
                                Text(copy.amount).font(.system(size: 36)).padding(.top, 27).padding(.bottom, 24).accessibilityIdentifier("confirmation-amount")
                                Avatar(recipient: payment.recipient, size: 50)
                                RecipientNameLines(recipient: payment.recipient, confirmation: true).padding(.top, 22)
                                Text(copy.siriExplanation).font(.system(size: 13)).multilineTextAlignment(.center).lineSpacing(2).fixedSize(horizontal: false, vertical: true).padding(.top, 68).accessibilityIdentifier("siri-explanation")
                                SiriDemoButton { store.explain("Add to Siri", "This is a demonstration only. No Siri integration, notification, or real transfer is created.") }.padding(.top, 18)
                            }.opacity(content ? 1 : 0)
                            Spacer(minLength: 24)
                        }.padding(.horizontal, 20).frame(minHeight: geometry.size.height, alignment: .top)
                    }
                }
                PrimaryButton(title: "Done") { store.done() }.accessibilityIdentifier("confirmation-done").padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 26)
            }
        }.background(.white).task {
            if reduceMotion { check = true; content = true }
            else { withAnimation(.spring(duration: 0.3)) { check = true }; try? await Task.sleep(for: .milliseconds(250)); withAnimation(.easeIn(duration: 0.28)) { content = true } }
        }
    }
}
