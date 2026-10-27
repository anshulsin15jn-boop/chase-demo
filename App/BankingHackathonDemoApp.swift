import SwiftUI
import DemoCore

@main struct BankingHackathonDemoApp: App {
    @State private var store: DemoStore
    init() {
        let args = ProcessInfo.processInfo.arguments
        let demo = DemoStore(persists: !args.contains("--ui-testing") && !args.contains("--demo-screen"))
        if let i = args.firstIndex(of: "--demo-screen"), args.indices.contains(i + 1) { demo.preview(args[i + 1]) }
        _store = State(initialValue: demo)
    }
    var body: some Scene { WindowGroup { RootView().environment(store).preferredColorScheme(.light).tint(Style.blue) } }
}
struct RootView: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            Group { switch store.tab {
            case .accounts: AccountsHomeView()
            case .pay: PayTransferHubView()
            case .plan: VStack { ContentUnavailableView("Plan & track", systemImage: "chart.bar", description: Text("Your fictional goals start here.")); Button("Explore demo planning") { store.explain("Plan & track") } }
            case .more: MoreView()
            } }.background(Style.background).safeAreaInset(edge: .bottom, spacing: 0) { BottomBar() }
            .navigationDestination(for: Route.self) { route in
                Group { switch route { case .directory: RecipientDirectoryView(); case .search: RecipientSearchView(); case .amount: EnterAmountView(); case .review: ReviewPaymentView(); case .confirmation: ConfirmationView() } }.toolbar(.hidden, for: .navigationBar).navigationBarBackButtonHidden()
            }.toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $store.showWelcome) { WelcomeView().interactiveDismissDisabled() }
        .sheet(item: $store.sheet) { sheet in DemoSheetView(sheet: sheet) }
        .alert("Check your demo payment", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
        .confirmationDialog("Discard this demo payment?", isPresented: $store.discard, titleVisibility: .visible) { Button("Discard payment", role: .destructive) { store.clearDraft() }; Button("Keep editing", role: .cancel) {} }
    }
}
struct BottomBar: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        HStack(spacing: 0) { ForEach(RootTab.allCases, id: \.self) { tab in Button { store.tab = tab } label: { VStack(spacing: 4) { Image(systemName: tab.icon).font(.system(size: 23, weight: .regular)); Text(tab.rawValue).font(.system(size: 10)) }.frame(maxWidth: .infinity).frame(height: 58).foregroundStyle(store.tab == tab ? Style.blue : Style.gray) }.accessibilityIdentifier("tab-\(tab.rawValue)") } }.padding(.horizontal, 6).background(.white, in: Capsule()).shadow(color: .black.opacity(0.04), radius: 12, y: 5).padding(.horizontal, 3).padding(.bottom, 3).background(Style.background.opacity(0.9))
    }
}
struct WelcomeView: View {
    @Environment(DemoStore.self) private var store
    var body: some View { VStack(spacing: 24) { Image(systemName: "building.columns.circle").font(.system(size: 70, weight: .light)).foregroundStyle(Style.blue); Text("Banking Hackathon Demo").font(.largeTitle.bold()).multilineTextAlignment(.center); Text("Fictional accounts. Simulated payments.").font(.headline); Text("An independent SwiftUI hackathon project inspired by banking interfaces. Not affiliated with Chase or Zelle. No real money moves and no banking sign in is available.").multilineTextAlignment(.center).foregroundStyle(Style.gray); Text("Demo clock: \(Demo.day(store.now))").font(.footnote); PrimaryButton(title: "Enter demo") { store.showWelcome = false }.accessibilityIdentifier("enter-demo") }.padding(28) }
}
struct MoreView: View {
    @Environment(DemoStore.self) private var store
    @State private var reset = false
    var body: some View { VStack(alignment: .leading, spacing: 20) { Text("More").font(.largeTitle.bold()); Text("Banking Hackathon Demo").font(.title2); Text("All data is fictional. Payments, recipient additions, QR scanning, and shortcuts are local simulations.").foregroundStyle(Style.gray); Text("Demo date: \(Demo.day(store.now))"); MenuRow(title: "Simulated activity", icon: "list.bullet.rectangle") { store.sheet = .activity }; Button("Reset demo", role: .destructive) { reset = true }.accessibilityIdentifier("reset-demo"); Spacer() }.padding(20).confirmationDialog("Restore fictional fixtures and clear activity?", isPresented: $reset, titleVisibility: .visible) { Button("Reset demo", role: .destructive) { store.reset() } } }
}
