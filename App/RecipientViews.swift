import SwiftUI
import DemoCore
struct RecipientDirectoryView: View {
    @Environment(DemoStore.self) private var store
    @State private var billExpanded = false
    @State private var registered = true
    var body: some View {
        VStack(spacing: 0) {
            ZStack { Text("Pay bills & send money with Zelle®").font(.system(size: 16, weight: .semibold)).lineLimit(1).truncationMode(.middle).padding(.horizontal, 65); HStack { Button { store.path = [] } label: { Image(systemName: "chevron.left").font(.system(size: 22)).frame(width: 44, height: 54) }.accessibilityLabel("Back"); Spacer(); Button { store.explain("Payment settings") } label: { Image(systemName: "gearshape").font(.system(size: 21)).frame(width: 44, height: 54) } }.foregroundStyle(Style.gray).padding(.horizontal, 10) }.frame(height: 64).background(Style.background)
            HStack(spacing: 0) { tab("Pay", due: false); tab("Payments due", due: true) }.background(Style.background)
            if store.directoryDue {
                VStack { if store.ledger.payments.filter(\.scheduled).isEmpty { ContentUnavailableView("No payments due", systemImage: "calendar.badge.checkmark", description: Text("Future demo payments appear here.")) } else { ActivityList(scheduledOnly: true) }; Button("View recipients") { store.directoryDue = false } }.frame(maxHeight: .infinity)
            } else {
                ScrollView { VStack(spacing: 0) {
                    HStack { Button { store.path.append(.search) } label: { HStack(spacing: 10) { Image(systemName: "magnifyingglass").font(.system(size: 22)); Text("Search your recipients").font(.system(size: 16)); Spacer() }.foregroundStyle(Style.gray) }.accessibilityIdentifier("recipient-search"); Divider().frame(height: 22); Button { store.sheet = .add } label: { Label("Add", systemImage: "plus.circle").font(.system(size: 13)) }.accessibilityIdentifier("add-recipient") }.padding(.horizontal, 20).frame(height: 56)
                    Divider()
                    Button { store.sheet = .qr } label: { HStack(spacing: 12) { Image(systemName: "qrcode.viewfinder").font(.system(size: 30)).foregroundStyle(Style.gray); Text("Scan QR code to pay with").font(.system(size: 13)).foregroundStyle(Color.black); Text("Zelle®").font(.system(size: 13, weight: .bold)).foregroundStyle(Style.purple); Spacer(minLength: 0); Image(systemName: "chevron.right").foregroundStyle(Style.gray) }.padding(.horizontal, 22).frame(height: 72) }
                    HStack { Text("Recent recipients").font(.system(size: 11, weight: .medium)); Spacer() }.padding(.horizontal, 20).frame(height: 38).background(Style.background)
                    ScrollView(.horizontal, showsIndicators: false) { HStack(alignment: .top, spacing: 4) { ForEach(store.recipients.prefix(5)) { recipient in Button { store.select(recipient) } label: { VStack(spacing: 9) { Avatar(recipient: recipient, size: 38); Text(recipient.name).font(.system(size: 16)).foregroundStyle(Color.black).multilineTextAlignment(.center); Text(recipient.contact).font(.system(size: 10)).foregroundStyle(Style.gray).multilineTextAlignment(.center) }.frame(width: 94).padding(.top, 16).padding(.bottom, 8) }.accessibilityIdentifier("recent-\(recipient.id)") } }.padding(.horizontal, 18) }.frame(minHeight: 200, alignment: .top)
                    section("Bill Pay recipients", expanded: $billExpanded)
                    if billExpanded { Text("No bill recipients yet. Add a fictional recipient to try a demo payment.").font(.footnote).foregroundStyle(Style.gray).padding(20) }
                    section("Registered with Zelle®", expanded: $registered)
                    if registered { VStack(spacing: 0) { ForEach(store.recipients.sorted { $0.name < $1.name }) { recipient in RecipientRow(recipient: recipient) { store.select(recipient) } } }.padding(.horizontal, 18) }
                } }
            }
        }.background(.white)
    }
    func tab(_ title: String, due: Bool) -> some View { Button { store.directoryDue = due } label: { Text(title).font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity).frame(height: 40).foregroundStyle(store.directoryDue == due ? Style.blue : Style.gray).overlay(alignment: .bottom) { if store.directoryDue == due { Rectangle().fill(Style.blue).frame(height: 4) } } } }
    func section(_ title: String, expanded: Binding<Bool>) -> some View { Button { expanded.wrappedValue.toggle() } label: { HStack { Text(title).font(.system(size: 11, weight: .semibold)); Spacer(); Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down").font(.system(size: 18)).foregroundStyle(Style.gray) }.foregroundStyle(Color.black).padding(.horizontal, 20).frame(height: 51).background(Style.background).overlay(alignment: .bottom) { Rectangle().fill(Color(.systemGray4)).frame(height: 0.5).padding(.horizontal, 18) } } }
}
struct RecipientSearchView: View {
    @Environment(DemoStore.self) private var store
    @State private var query = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) { Button { focused = false; store.path.removeLast() } label: { Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(Style.gray).frame(width: 38, height: 54) }.accessibilityLabel("Back"); Image(systemName: "magnifyingglass").foregroundStyle(Style.gray); TextField("Search your recipients", text: $query).font(.system(size: 17)).focused($focused).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("search-field"); if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search") } }.padding(.trailing, 20).frame(height: 72)
            Divider()
            ScrollView { LazyVStack(spacing: 0) { ForEach(Demo.filter(store.recipients, query: query)) { recipient in RecipientRow(recipient: recipient) { focused = false; store.select(recipient) } }; if Demo.filter(store.recipients, query: query).isEmpty { ContentUnavailableView.search(text: query) } }.padding(.horizontal, 18) }.scrollDismissesKeyboard(.interactively)
        }.background(.white).task { try? await Task.sleep(for: .milliseconds(300)); focused = true }
    }
}
