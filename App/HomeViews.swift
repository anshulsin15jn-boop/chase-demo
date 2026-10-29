import SwiftUI
import DemoCore

struct AccountsHomeView: View {
    @Environment(DemoStore.self) private var store
    private let products: [(String, String)] = [("creditcard.fill", "Credit cards"), ("creditcard", "Checking"), ("banknote.fill", "Savings\n& CDs"), ("person.2.fill", "Work with\nour advisors"), ("briefcase.fill", "Business")]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button { store.explain("Open a demo account") } label: { Image(systemName: "rectangle.stack.badge.plus").font(.system(size: 19)) }
                    Button { store.explain("Search", "Search is simulated here. Use Pay & transfer to search fictional recipients.") } label: { Text("What are you looking for?").font(.system(size: 12)).foregroundStyle(Style.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).padding(.vertical, 7).overlay(Capsule().stroke(Style.gray, lineWidth: 0.7)) }
                    Button { store.explain("Messages") } label: { Image(systemName: "bubble.left.and.bubble.right.fill") }
                    Button { store.sheet = .profile } label: { Image(systemName: "person.crop.circle").font(.system(size: 20)) }
                }.foregroundStyle(Style.gray).padding(.top, 14).padding(.bottom, 20)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { quick("+", width: 46) { store.explain("Quick actions") }; quick("Send | Zelle®") { store.directory() }; quick("Deposit checks") { store.explain("Deposit checks") }; quick("Pay bills") { store.directory(due: true) } }.padding(.vertical, 2) }.padding(.bottom, 24)
                HStack { Text("Accounts").font(.system(size: 19, weight: .medium)); Spacer(); Button { store.explain("Account options") } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)).foregroundStyle(Style.gray) } }.padding(.bottom, 14)
                VStack(spacing: 0) {
                    HStack { Text("Bank accounts (\(store.ledger.accounts.count))").font(.system(size: 12)); Spacer() }.padding(12).frame(height: 42).foregroundStyle(.white).background(Style.gradient)
                    ForEach(store.ledger.accounts) { account in
                        VStack(alignment: .leading, spacing: 10) {
                            Button { store.transactionAccountID = account.id; store.path.append(.transactions) } label: {
                                HStack { Text(store.accountLabel(account)).font(.system(size: 12)).accessibilityIdentifier("account-label-\(account.id)"); Image(systemName: "chevron.right").font(.system(size: 10)); Spacer() }.foregroundStyle(Color.black)
                            }
                            VStack(alignment: .trailing, spacing: 2) { Text(Demo.money(account.cents)).font(.system(size: 27)).accessibilityIdentifier("account-balance-\(account.id)"); Text("Available balance").font(.system(size: 11)).foregroundStyle(Style.gray) }.frame(maxWidth: .infinity, alignment: .trailing)
                        }.padding(12)
                        if account.id != store.ledger.accounts.last?.id { Divider() }
                    }
                    Button { store.explain("Link external accounts") } label: { HStack { Text("Link external accounts").font(.system(size: 12)); Spacer(); Image(systemName: "chevron.right").foregroundStyle(Style.gray) }.foregroundStyle(Color.black).padding(16).frame(minHeight: 44).overlay(RoundedRectangle(cornerRadius: Style.radius).stroke(Color(.systemGray4), lineWidth: 0.7)) }
                }.background(.white).clipShape(RoundedRectangle(cornerRadius: Style.radius)).overlay(RoundedRectangle(cornerRadius: Style.radius).stroke(Color(.systemGray4), lineWidth: 0.7))
                Text("Explore more products").font(.system(size: 16, weight: .medium)).padding(.top, 28).padding(.bottom, 14)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 9) { ForEach(products, id: \.1) { icon, title in Button { store.explain(title.replacingOccurrences(of: "\n", with: " ")) } label: { VStack(spacing: 10) { Image(systemName: icon).symbolRenderingMode(.palette).foregroundStyle(Style.blue, Color.cyan, Color.orange).font(.system(size: 26)); Text(title).font(.system(size: 11, weight: .medium)).multilineTextAlignment(.center).frame(height: 32) }.frame(width: 62, height: 90).background(.white, in: RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.7)) } } } }
                HStack { Spacer(); Button("Explore products") { store.explain("Explore products") }.font(.system(size: 13, weight: .medium)).padding(.horizontal, 14).padding(.vertical, 7).background(Style.blue.opacity(0.07), in: Capsule()) }.padding(.top, 24).padding(.bottom, 32)
                Button { store.explain("Credit Journey", "This demo does not access or calculate a real credit score.") } label: { HStack { VStack(alignment: .leading, spacing: 6) { Text("Credit Journey®").font(.system(size: 12)); Text("Get your free credit score").font(.system(size: 19, weight: .semibold)) }; Spacer(); Image(systemName: "gauge.with.dots.needle.50percent").font(.system(size: 27)).padding(10).background(Style.blue.opacity(0.06), in: Circle()) }.foregroundStyle(Style.navy).padding(16).overlay(RoundedRectangle(cornerRadius: Style.radius).stroke(Color(.systemGray4), lineWidth: 0.7)) }
                Text("Independent hackathon simulation").font(.caption2).foregroundStyle(Style.gray).padding(.vertical, 16)
            }.padding(.horizontal, 17)
        }.background(Style.background)
    }
    func quick(_ title: String, width: CGFloat? = nil, action: @escaping () -> Void) -> some View { Button(action: action) { Text(title).font(.system(size: title == "+" ? 28 : 11, weight: .semibold)).frame(minWidth: width).padding(.horizontal, title == "+" ? 0 : 16).frame(height: 30).background(.white, in: Capsule()).shadow(color: .black.opacity(0.14), radius: 0.7, y: 1) }.accessibilityIdentifier(title == "Send | Zelle®" ? "send-zelle" : title) }
}
struct PayTransferHubView: View {
    @Environment(DemoStore.self) private var store
    private let actions = [("creditcard", "Pay bills"), ("dollarsign.circle", "Send money\nwith Zelle®"), ("building.columns", "Wires & global\ntransfers"), ("rectangle.2.swap", "Transfer"), ("text.bubble", "Request/split\nwith Zelle®"), ("creditcard.and.123", "Deposit\nchecks")]
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 28) { HStack { Spacer(); Button { store.explain("Profile") } label: { Image(systemName: "person.crop.circle").font(.system(size: 23)) } }; Text("Pay & Transfer").font(.system(size: 27, weight: .semibold)) }.foregroundStyle(.white).padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 22).frame(maxWidth: .infinity).background(Style.gradient)
                Button { store.explain("Demo notice", "Every payment here is a local simulation. Names and recipients stay on this device, and nothing is sent externally.") } label: { HStack(alignment: .top, spacing: 10) { Image(systemName: "exclamationmark.triangle").foregroundStyle(Style.blue); Text("You have 1 message that requires immediate action.").font(.system(size: 16, weight: .medium)).foregroundStyle(Color.black).multilineTextAlignment(.leading); Spacer(minLength: 0); Image(systemName: "chevron.right").foregroundStyle(Style.gray) }.padding(17).background(.white, in: RoundedRectangle(cornerRadius: Style.radius)).overlay(RoundedRectangle(cornerRadius: Style.radius).stroke(Color(.systemGray4), lineWidth: 0.7)) }.padding(.horizontal, 18).padding(.top, -16)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 32) { ForEach(Array(actions.enumerated()), id: \.offset) { index, item in Button { switch index { case 0: store.directory(due: true); case 1: store.directory(); default: store.explain(item.1.replacingOccurrences(of: "\n", with: " ")) } } label: { VStack(spacing: 8) { Image(systemName: item.0).font(.system(size: 27, weight: .ultraLight)).frame(width: 56, height: 56).overlay(Circle().stroke(Style.blue, lineWidth: 1.2)); Text(item.1).font(.system(size: 11, weight: .medium)).multilineTextAlignment(.center).frame(height: 32) }.foregroundStyle(Style.blue) }.accessibilityIdentifier("hub-action-\(index)") } }.padding(.horizontal, 30).padding(.top, 24).padding(.bottom, 20)
                VStack(spacing: 0) { MenuRow(title: "See activity", icon: "list.bullet.rectangle") { store.sheet = .activity }; MenuRow(title: "Manage recipients", icon: "person.3") { store.directory() }; MenuRow(title: "Manage external accounts", icon: "building.columns") { store.explain("Manage external accounts") }; MenuRow(title: "Settings", icon: "gearshape") { store.explain("Settings") } }.padding(.horizontal, 18)
            }
        }.background(Style.background, ignoresSafeAreaEdges: .bottom).background(alignment: .top) { Style.gradient.ignoresSafeArea(edges: .top) }
    }
}
