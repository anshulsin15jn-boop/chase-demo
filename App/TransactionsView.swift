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
    var recipientNumber = ""
}

struct TransactionsView: View {
    var preview = false
    @Environment(DemoStore.self) private var store
    @State private var accountID = "checking"
    @State private var search = ""
    @State private var filter = "All"
    @State private var selected: TransactionItem?
    private var account: Account? { store.ledger.accounts.first { $0.id == accountID } ?? store.ledger.accounts.first }
    private var items: [TransactionItem] {
        guard let account else { return [] }
        let payments = store.ledger.payments.filter { $0.account.id == account.id || $0.recipient.id == "transfer-" + account.id }.map { payment in
            let transfer = payment.recipient.id.hasPrefix("transfer-")
            let incoming = transfer && payment.account.id != account.id
            return TransactionItem(id: payment.id.uuidString, title: transfer ? "TRANSFER \(incoming ? "FROM " + payment.account.type : "TO " + payment.recipient.displayName)" : "ZELLE PAYMENT TO \(payment.recipient.displayName.uppercased())", subtitle: payment.message.isEmpty ? "Zelle® payment" : payment.message, cents: incoming ? payment.cents : -payment.cents, date: TransactionPresentation.date(for: payment, calendar: store.calendar), symbol: transfer ? "arrow.left.arrow.right" : "person.crop.circle", scheduled: payment.scheduled, recipientNumber: transfer ? "" : payment.recipient.phoneDigits.isEmpty ? payment.recipient.email : payment.recipient.phoneDigits)
        }
        let samples: [(String, String, Int, String)] = account.id == "savings"
            ? [("INTEREST PAYMENT", "Interest earned", 126, "building.columns"), ("ONLINE TRANSFER FROM CHECKING", "Account transfer", 15000, "arrow.left.arrow.right")]
            : [("UBER EATS", "Uber", -1231, "bag"), ("ZELLE PAYMENT FROM AVERY MORGAN", "Zelle® payment", 2500, "person.crop.circle"), ("AMAZON MARKETPLACE", "Amazon.com", -2614, "shippingbox"), ("TARGET", "Debit card purchase", -1849, "cart"), ("ZELLE PAYMENT TO JORDAN ELLIS", "Dinner", -1500, "person.crop.circle"), ("COFFEE HOUSE", "Debit card purchase", -575, "cup.and.saucer"), ("GROCERY MARKET", "Debit card purchase", -4238, "basket"), ("PAYROLL DEPOSIT", "Direct deposit", 62500, "building.columns")]
        let history = samples.enumerated().map { index, entry in
            TransactionItem(id: "sample-\(account.id)-\(index)", title: entry.0, subtitle: entry.1, cents: entry.2, date: store.calendar.date(byAdding: .day, value: -(index / 2 + 1), to: store.calendar.startOfDay(for: store.now)) ?? store.now, symbol: entry.3, scheduled: false, recipientNumber: entry.0.contains("AVERY MORGAN") ? "2025550188" : entry.0.contains("JORDAN ELLIS") ? "2025550146" : "")
        }
        return (payments + history).sorted { $0.date > $1.date }
    }
    @State private var recentFirst = true
    private var filtered: [TransactionItem] {
        let matches = items.filter { item in
            (filter == "All" || (filter == "Money in" && item.cents > 0) || (filter == "Money out" && item.cents < 0)) &&
            (search.isEmpty || "\(item.title) \(item.recipientNumber) \(item.subtitle)".localizedCaseInsensitiveContains(search))
        }
        return matches.sorted { left, right in
            let lp = status(left) == "Pending", rp = status(right) == "Pending"
            if lp != rp { return lp }
            return recentFirst ? left.date > right.date : left.date < right.date
        }
    }
    private func balance(after item: TransactionItem) -> Int {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return account?.cents ?? 0 }
        return (account?.cents ?? 0) - items.prefix(index).filter { !$0.scheduled }.reduce(0) { $0 + $1.cents }
    }
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if preview {
                ForEach(Array(filtered.prefix(2))) { item in transactionButton(item) }
            } else {
                header
                accountBar
                HStack {
                    Spacer()
                    Button { recentFirst.toggle() } label: {
                        Label("Sort by : \(recentFirst ? "Recent" : "Oldest")", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                    }.accessibilityIdentifier("transaction-sort")
                }.padding(.horizontal, 16).frame(height: 50).background(TransactionPalette.chrome)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                            if status(item) == "Pending" {
                                if index == 0 { pendingHeader }
                            } else if index == 0 || status(filtered[index - 1]) == "Pending" || !store.calendar.isDate(filtered[index - 1].date, inSameDayAs: item.date) {
                                Text(store.dateLabel(item.date)).font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(TransactionPalette.secondary).frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12).frame(height: 48).background(TransactionPalette.chrome)
                            }
                            transactionButton(item)
                        }
                        if filtered.isEmpty { ContentUnavailableView.search(text: search).padding(.top, 32) }
                    }
                }.scrollDismissesKeyboard(.interactively)
            }
        }
        .background(TransactionPalette.canvas)
        .environment(\.colorScheme, .light)
        .tint(TransactionPalette.blue)
        .onAppear { accountID = store.transactionAccountID; store.refreshDay() }
        .sheet(item: $selected) { item in
            NavigationStack {
                List {
                    Section { Text(item.title); Text(amount(item)).font(.title2) }
                    Section("Details") {
                        LabeledContent("Status", value: status(item))
                        if !item.recipientNumber.isEmpty { LabeledContent("Recipient number", value: item.recipientNumber) }
                        LabeledContent("Date", value: store.dateLabel(item.date))
                        LabeledContent("Account", value: account.map { store.accountLabel($0) } ?? "")
                        LabeledContent("Description", value: item.subtitle)
                        if !item.scheduled { LabeledContent("Balance after transaction", value: Demo.money(balance(after: item))) }
                    }
                    Section { Text("Independent hackathon simulation. No real money moved.").font(.footnote) }
                }.navigationTitle("Transaction details").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { selected = nil } } }
            }.presentationDragIndicator(.visible).environment(\.colorScheme, .light)
        }
    }

    private var header: some View {
        ZStack {
            Text("Transactions").font(.system(size: 17, weight: .medium)).foregroundStyle(TransactionPalette.primary)
            HStack {
                Button { store.path.removeLast() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 19, weight: .semibold)).frame(width: 44, height: 48)
                }.accessibilityLabel("Back")
                Spacer()
                Menu {
                    Picker("Transaction type", selection: $filter) {
                        ForEach(["All", "Money in", "Money out"], id: \.self) { Text($0) }
                    }
                    Button("About this demo") { store.explain("Transactions", "Fictional sample history and local demo payments. No real banking service is connected.") }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 22, weight: .light)).frame(width: 44, height: 48)
                }.accessibilityLabel("Transaction options")
            }.foregroundStyle(TransactionPalette.secondary).padding(.horizontal, 16)
        }.frame(height: 48).background(TransactionPalette.chrome.ignoresSafeArea(edges: .top))
    }

    private var accountBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Showing").font(.system(size: 12)).foregroundStyle(Style.gray)
            Menu {
                ForEach(store.ledger.accounts) { value in
                    Button(store.accountLabel(value)) { accountID = value.id; store.transactionAccountID = value.id }
                }
            } label: {
                Text(account.map { "\($0.type == "CHECKING" ? "HIGH SCHOOL CHECKING" : "SAVINGS") (...\($0.displaySuffix))" } ?? "Select account")
                    .font(.system(size: 13)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityIdentifier("transaction-account")
            Divider()
            searchBar
        }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(TransactionPalette.line, lineWidth: 0.7))
            .padding(.horizontal, 12).padding(.bottom, 4).background(TransactionPalette.chrome)
    }

    private var pendingHeader: some View {
        HStack {
            let pending = filtered.filter { status($0) == "Pending" }
            Text("Pending (\(pending.count))")
            Spacer()
            Text(Demo.money(abs(pending.reduce(0) { $0 + $1.cents })))
        }.font(.system(size: 12, weight: .medium)).padding(.horizontal, 12).frame(height: 38)
            .overlay(alignment: .bottom) { TransactionPalette.line.frame(height: 0.5) }
    }
    private func transactionButton(_ item: TransactionItem) -> some View {
        Button { selected = item } label: {
            TransactionRow(item: item, balance: balance(after: item), status: status(item), preview: preview)
        }.buttonStyle(.plain).accessibilityIdentifier("transaction-\(item.id)")
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            TextField("Search or filter transactions", text: $search).focused($searchFocused)
                .font(.system(size: 14)).autocorrectionDisabled().textInputAutocapitalization(.never)
                .accessibilityIdentifier("transaction-search")
            if !search.isEmpty {
                Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search")
            }
        }.foregroundStyle(TransactionPalette.secondary).padding(10).background(.white, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(TransactionPalette.line, lineWidth: 0.7))
    }
    private func status(_ item: TransactionItem) -> String {
        TransactionPresentation.status(date: item.date, scheduled: item.scheduled, isZelle: item.title.contains("ZELLE"), now: store.now, calendar: store.calendar)
    }
    private func amount(_ item: TransactionItem) -> String {
        (item.cents < 0 ? "-" : "") + Demo.money(abs(item.cents))
    }
}

private enum TransactionPalette {
    static let canvas = Color.white
    static let chrome = Color(red: 246.0 / 255, green: 247.0 / 255, blue: 251.0 / 255)
    static let line = Color(red: 0.83, green: 0.85, blue: 0.88)
    static let primary = Color.black
    static let secondary = Style.gray
    static let blue = Style.blue
    static let debit = Color(red: 0.72, green: 0.17, blue: 0.20)
}

private struct TransactionRow: View {
    let item: TransactionItem
    let balance: Int
    let status: String
    var preview = false
    private var isZelle: Bool { item.title.contains("ZELLE") }
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            TransactionMark(title: item.title, symbol: item.symbol, incoming: item.cents > 0)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title + (isZelle && !item.recipientNumber.isEmpty ? " " + item.recipientNumber : ""))
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(TransactionPalette.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(isZelle ? "transaction-number-\(item.id)" : "transaction-description-\(item.id)")
                if status != "Posted" && (preview || status != "Pending") {
                    Text(status).accessibilityIdentifier("transaction-status-\(item.id)").font(.system(size: 14)).foregroundStyle(TransactionPalette.secondary)
                } else if !isZelle {
                    Text(item.subtitle).font(.system(size: 14)).foregroundStyle(TransactionPalette.secondary)
                }
                if !item.scheduled {
                    Text(status == "Pending" ? "--" : Demo.money(balance)).font(.system(size: 14)).foregroundStyle(TransactionPalette.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            VStack {
                HStack(spacing: 12) {
                    Text((item.cents < 0 ? "-" : "") + Demo.money(abs(item.cents)))
                        .font(.system(size: 16)).foregroundStyle(item.cents < 0 ? TransactionPalette.debit : TransactionPalette.blue)
                        .fixedSize()
                    if !isZelle {
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .medium)).foregroundStyle(TransactionPalette.secondary)
                    }
                }
                Spacer(minLength: 0)
            }.padding(.top, 19)
        }.padding(.leading, 16).padding(.trailing, isZelle ? 36 : 16)
            .frame(minHeight: isZelle ? (preview ? 108 : 96) : 88)
            .overlay(alignment: .bottom) { TransactionPalette.line.frame(height: 0.5).padding(.leading, 16) }
            .contentShape(Rectangle())
    }
}

/// Small vector merchant marks, matching the reference's circular treatments.
private struct TransactionMark: View {
    let title: String
    let symbol: String
    let incoming: Bool
    var body: some View {
        ZStack {
            Circle().fill(title == "UBER EATS" ? Color(red: 0, green: 0.75, blue: 0.39) : title == "AMAZON MARKETPLACE" ? .white : TransactionPalette.chrome)
            if title == "UBER EATS" {
                Text("Uber\nEats").font(.system(size: 16, weight: .semibold)).tracking(-1).lineSpacing(-4).foregroundStyle(.black)
            } else if title == "AMAZON MARKETPLACE" {
                VStack(spacing: -7) {
                    Text("amazon").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                    Text("⌣").font(.system(size: 22, weight: .bold)).foregroundStyle(.orange)
                }
            } else {
                Image(systemName: title.contains("ZELLE") ? (incoming ? "dollarsign.arrow.circlepath" : "person.crop.circle") : symbol)
                    .font(.system(size: 23, weight: .ultraLight)).foregroundStyle(TransactionPalette.secondary)
            }
        }.frame(width: 46, height: 46).overlay(Circle().stroke(TransactionPalette.line, lineWidth: 1))
            .accessibilityHidden(true)
    }
}
