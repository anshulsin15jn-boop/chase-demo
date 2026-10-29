import SwiftUI
import DemoCore

struct AccountDetailsView: View {
    @Environment(DemoStore.self) private var store
    @State private var expanded = false
    private var account: Account? { store.ledger.accounts.first { $0.id == store.transactionAccountID } }
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(account.map { "\($0.type == "CHECKING" ? "HIGH SCHOOL CHECKING" : "SAVINGS") (...\($0.displaySuffix))" } ?? "Account")
                    .font(.system(size: 15, weight: .semibold)).padding(.horizontal, 44).lineLimit(1)
                HStack { Button { store.path.removeLast() } label: { Image(systemName: "chevron.left").frame(width: 44, height: 48) }.accessibilityLabel("Back"); Spacer() }
            }.frame(height: 48)
            ScrollView {
                VStack(spacing: 24) {
                    balanceCard
                    HStack {
                        shortcut("Pay", icon: "creditcard.fill") { store.path.append(.accountPayments) }
                        shortcut("Transfer", icon: "rectangle.2.swap") { store.sheet = .transfer }
                        shortcut("More", icon: "ellipsis.circle") { store.sheet = .profile }
                    }.padding(.horizontal, 10).padding(.top, 22)
                    Button { store.sheet = .profile } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Manage account").font(.system(size: 16, weight: .medium)); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12)) }
                            Text("Access tools & services for your account").font(.system(size: 12)).foregroundStyle(Style.gray)
                        }.foregroundStyle(Color.black).padding(19).accountCard()
                    }
                    VStack(spacing: 0) {
                        Button { store.path.append(.transactions) } label: {
                            HStack { Text("See all transactions").font(.system(size: 16, weight: .medium)); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Style.gray) }
                                .foregroundStyle(Color.black).padding(16)
                        }.accessibilityIdentifier("see-all-transactions")
                        TransactionsView(preview: true)
                    }.accountCard()
                }.padding(.horizontal, 6).padding(.top, 8).padding(.bottom, 24)
            }
        }.background(Color(red: 246.0 / 255, green: 247.0 / 255, blue: 251.0 / 255)).environment(\.colorScheme, .light)
    }
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .trailing, spacing: 5) {
                Text(Demo.money(account?.cents ?? 0)).font(.system(size: 29)).accessibilityIdentifier("detail-balance")
                Text("Available balance").font(.system(size: 12))
            }.frame(maxWidth: .infinity, alignment: .trailing)
            Text("Account details").font(.system(size: 16, weight: .medium))
            balanceLine("Available balance")
            balanceLine("Present balance")
            if expanded {
                HStack { Text("Account number"); Spacer(); Text("•••• \(account?.displaySuffix ?? "")") }.font(.system(size: 12))
                HStack { Text("Account owner"); Spacer(); Text(store.fullName) }.font(.system(size: 12))
            }
        }.padding(16).padding(.bottom, 28).accountCard()
            .overlay(alignment: .bottom) {
                Button { expanded.toggle() } label: {
                    HStack(spacing: 8) { Text(expanded ? "Hide details" : "Show details"); Image(systemName: expanded ? "chevron.up" : "chevron.down") }
                        .font(.system(size: 13)).padding(.horizontal, 30).frame(height: 36).background(Color(red: 0.91, green: 0.95, blue: 0.99), in: Capsule())
                }.offset(y: 18).accessibilityIdentifier("show-account-details")
            }
    }
    private func balanceLine(_ title: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Style.gray); Spacer()
            Text(Demo.money(account?.cents ?? 0))
            Button { store.explain(title, "This is the balance of your local simulated account.") } label: { Image(systemName: "questionmark.circle").font(.system(size: 12)) }.accessibilityLabel("About \(title)")
        }.font(.system(size: 12))
    }
    private func shortcut(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Group {
                    if title == "Pay" || title == "Transfer" { AccountShortcutGlyph(transfer: title == "Transfer") }
                    else { Image(systemName: icon).font(.system(size: 23, weight: .light)) }
                }.frame(width: 50, height: 50).background(.white, in: Circle())
                Text(title).font(.system(size: 13))
            }.frame(maxWidth: .infinity)
        }.accessibilityIdentifier("account-\(title.lowercased())")
    }
}

private struct AccountShortcutGlyph: View {
    let transfer: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2).fill(Color(red: 0, green: 0.40, blue: 0.78))
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: 32, y: 0))
                path.addLine(to: CGPoint(x: 12, y: 22)); path.addLine(to: CGPoint(x: 0, y: 22)); path.closeSubpath()
            }.fill(Color(red: 0.22, green: 0.65, blue: 0.98))
            if transfer {
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
            } else {
                Circle().fill(.yellow).frame(width: 3, height: 3).offset(x: -10, y: -5)
                RoundedRectangle(cornerRadius: 1).fill(.white).frame(width: 6, height: 3).offset(x: -9, y: 4)
            }
        }.frame(width: 32, height: 22)
    }
}

private extension View {
    func accountCard() -> some View {
        background(.white, in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(.systemGray4), lineWidth: 0.7))
    }
}

struct DemoTransferView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var source = "checking"
    @State private var destination = "savings"
    @State private var amount = ""
    @State private var error: String?
    var body: some View {
        Form {
            Picker("From", selection: $source) { ForEach(store.ledger.accounts) { Text(store.accountLabel($0)).tag($0.id) } }
            Picker("To", selection: $destination) { ForEach(store.ledger.accounts) { Text(store.accountLabel($0)).tag($0.id) } }
            TextField("Amount in dollars", text: $amount).keyboardType(.decimalPad)
            if let error { Text(error).foregroundStyle(Style.error) }
            Button("Transfer money") {
                do { try store.transfer(from: source, to: destination, amount: amount); dismiss() }
                catch { self.error = (error as? PaymentError)?.rawValue ?? error.localizedDescription }
            }
            Text("Local demo transfer only. No real money moves.").font(.footnote).foregroundStyle(Style.gray)
        }.navigationTitle("Transfer money")
            .onAppear { source = store.transactionAccountID; destination = store.ledger.accounts.first { $0.id != source }?.id ?? source }
    }
}
