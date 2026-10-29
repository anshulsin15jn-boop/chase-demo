import SwiftUI
import DemoCore

/// Presentation-only sample history. It never changes the payment ledger or balances.
private struct TransactionItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let cents: Int
    let date: Date
    let symbol: String
    let scheduled: Bool
}

struct TransactionsView: View {
    @Environment(DemoStore.self) private var store
    @State private var accountID = "checking"
    @State private var search = ""
    @State private var filter = "All"
    @State private var selected: TransactionItem?
    private var account: Account? { store.ledger.accounts.first { $0.id == accountID } ?? store.ledger.accounts.first }
    private var items: [TransactionItem] {
        guard let account else { return [] }
        let payments = store.ledger.payments.filter { $0.account.id == account.id }.map {
            TransactionItem(id: $0.id.uuidString, title: "ZELLE PAYMENT TO \($0.recipient.displayName.uppercased())", subtitle: $0.message.isEmpty ? "Zelle® payment" : $0.message, cents: -$0.cents, date: $0.date, symbol: "person.crop.circle", scheduled: $0.scheduled)
        }
        let samples: [(String, String, Int, String)] = account.id == "savings"
            ? [("INTEREST PAYMENT", "Interest earned", 126, "building.columns"), ("ONLINE TRANSFER FROM CHECKING", "Account transfer", 15000, "arrow.left.arrow.right")]
            : [("UBER EATS", "Uber", -1231, "bag"), ("ZELLE PAYMENT FROM AVERY MORGAN", "Zelle® payment", 2500, "person.crop.circle"), ("AMAZON MARKETPLACE", "Amazon.com", -2614, "shippingbox"), ("TARGET", "Debit card purchase", -1849, "cart"), ("ZELLE PAYMENT TO JORDAN ELLIS", "Dinner", -1500, "person.crop.circle"), ("COFFEE HOUSE", "Debit card purchase", -575, "cup.and.saucer"), ("GROCERY MARKET", "Debit card purchase", -4238, "basket"), ("PAYROLL DEPOSIT", "Direct deposit", 62500, "building.columns")]
        let history = samples.enumerated().map { index, entry in
            TransactionItem(id: "sample-\(account.id)-\(index)", title: entry.0, subtitle: entry.1, cents: entry.2, date: store.calendar.date(byAdding: .day, value: -(index / 2 + 1), to: store.calendar.startOfDay(for: store.now)) ?? store.now, symbol: entry.3, scheduled: false)
        }
        return (payments + history).sorted { $0.date > $1.date }
    }
    private var filtered: [TransactionItem] {
        items.filter { item in
            (filter == "All" || (filter == "Money in" && item.cents > 0) || (filter == "Money out" && item.cents < 0)) &&
            (search.isEmpty || "\(item.title) \(item.subtitle)".localizedCaseInsensitiveContains(search))
        }
    }
    private func balance(after item: TransactionItem) -> Int {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return account?.cents ?? 0 }
        return (account?.cents ?? 0) - items.prefix(index).filter { !$0.scheduled }.reduce(0) { $0 + $1.cents }
    }
    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Transactions", back: { store.tab = .accounts })
            HStack {
                Menu {
                    ForEach(store.ledger.accounts) { value in
                        Button(store.accountLabel(value)) { accountID = value.id }
                    }
                } label: {
                    HStack { Text(account.map { store.accountLabel($0) } ?? "Select account").lineLimit(1); Spacer(); Image(systemName: "chevron.down") }
                        .font(.system(size: 12)).padding(10).background(.white, in: RoundedRectangle(cornerRadius: 5))
                }.accessibilityIdentifier("transaction-account")
                Image(systemName: "magnifyingglass").foregroundStyle(Style.blue)
            }.padding(.horizontal, 16).padding(.bottom, 8)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Style.gray)
                TextField("Search transactions", text: $search).font(.system(size: 14)).autocorrectionDisabled().accessibilityIdentifier("transaction-search")
                if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search") }
            }.padding(10).background(.white, in: RoundedRectangle(cornerRadius: 6)).padding(.horizontal, 16)
            Picker("Transaction type", selection: $filter) { ForEach(["All", "Money in", "Money out"], id: \.self) { Text($0) } }.pickerStyle(.segmented).padding(.horizontal, 16).padding(.vertical, 10)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                        if index == 0 || !store.calendar.isDate(filtered[index - 1].date, inSameDayAs: item.date) {
                            Text(store.dateLabel(item.date)).font(.system(size: 11)).foregroundStyle(Style.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.vertical, 10).background(Style.background)
                        }
                        Button { selected = item } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.symbol).font(.system(size: 20, weight: .light)).foregroundStyle(item.title.contains("ZELLE") ? Style.purple : Style.blue).frame(width: 40, height: 40).background(Style.background, in: Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top) {
                                        Text(item.title).font(.system(size: 13, weight: .medium)).multilineTextAlignment(.leading)
                                        Spacer(minLength: 6)
                                        Text((item.cents < 0 ? "-" : "+") + Demo.money(abs(item.cents))).font(.system(size: 13)).foregroundStyle(item.cents < 0 ? Style.error : Style.blue)
                                    }
                                    Text(item.scheduled ? "Scheduled · \(item.subtitle)" : item.subtitle).font(.system(size: 11)).foregroundStyle(Style.gray)
                                    if !item.scheduled { Text(Demo.money(balance(after: item))).font(.system(size: 11)).foregroundStyle(Style.gray) }
                                }
                                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Style.gray)
                            }.foregroundStyle(Color.black).padding(.horizontal, 16).padding(.vertical, 13).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("transaction-\(item.id)")
                        Divider().padding(.leading, 68)
                    }
                    if filtered.isEmpty { ContentUnavailableView.search(text: search) }
                    Text("Fictional sample history and local demo payments").font(.caption2).foregroundStyle(Style.gray).padding(16)
                }.background(.white)
            }.scrollDismissesKeyboard(.interactively)
        }.background(Style.background)
        .onAppear { accountID = store.transactionAccountID }
        .sheet(item: $selected) { item in
            NavigationStack {
                List {
                    Section { Text(item.title); Text((item.cents < 0 ? "-" : "+") + Demo.money(abs(item.cents))).font(.title2) }
                    Section("Details") {
                        LabeledContent("Status", value: item.scheduled ? "Scheduled" : "Posted")
                        LabeledContent("Date", value: store.dateLabel(item.date))
                        LabeledContent("Account", value: account.map { store.accountLabel($0) } ?? "")
                        LabeledContent("Description", value: item.subtitle)
                        if !item.scheduled { LabeledContent("Balance after transaction", value: Demo.money(balance(after: item))) }
                    }
                    Section { Text("Independent hackathon simulation. No real money moved.").font(.footnote) }
                }.navigationTitle("Transaction details").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { selected = nil } } }
            }.presentationDragIndicator(.visible)
        }
    }
}
