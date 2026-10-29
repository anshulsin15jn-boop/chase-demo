import SwiftUI
import UIKit
import DemoCore

@MainActor @main struct BankingHackathonDemoApp: App {
    @State private var store: DemoStore
    init() {
        #if DEBUG
        let value = DemoHarness.makeStore(arguments: ProcessInfo.processInfo.arguments) ?? DemoStore()
        #else
        let value = DemoStore()
        #endif
        _store = State(initialValue: value)
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(\.colorScheme, .light)
                .preferredColorScheme((store.tab == .pay && store.path.isEmpty) ? .dark : .light).tint(Style.blue)
        }
    }
}
struct RootView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            Group {
                switch store.tab {
                case .accounts: AccountsHomeView()
                case .pay: PayTransferHubView()
                case .plan: VStack { ContentUnavailableView("Plan & track", systemImage: "chart.bar", description: Text("Your local demo goals start here.")); Button("Explore demo planning") { store.explain("Plan & track") } }
                case .more: MoreView()
                }
            }.background(Style.background).safeAreaInset(edge: .bottom, spacing: 0) { BottomBar() }
            .navigationDestination(for: Route.self) { route in
                Group {
                    switch route {
                    case .accountDetails: AccountDetailsView()
                    case .accountPayments: PayTransferHubView()
                    case .transactions: TransactionsView()
                    case .directory: RecipientDirectoryView()
                    case .search: RecipientSearchView()
                    case .amount: EnterAmountView()
                    case .review: ReviewPaymentView()
                    case .confirmation: ConfirmationView()
                    }
                }.toolbar(.hidden, for: .navigationBar).navigationBarBackButtonHidden()
            }.toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: Binding(get: { store.needsFirstName }, set: { _ in })) { NavigationStack { OnboardingView().toolbar(.hidden, for: .navigationBar) }.interactiveDismissDisabled() }
        .sheet(item: $store.sheet) { DemoSheetView(sheet: $0) }
        .alert("Check your demo payment", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .confirmationDialog("Discard this demo payment?", isPresented: $store.discard, titleVisibility: .visible) {
            Button("Discard payment", role: .destructive) { store.clearDraft() }; Button("Keep editing", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, value in if value == .active { store.refreshDay() } }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in store.refreshDay() }
    }
}
struct OnboardingView: View {
    @Environment(DemoStore.self) private var store
    @State private var name = ""
    @State private var middle = ""
    @State private var last = ""
    @FocusState private var focused: NameField?
    private enum NameField: Hashable { case first, middle, last }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Chase Demo").font(.largeTitle.bold())
                Text(store.state.profile == nil ? "What’s your name?" : "Complete your name").font(.title2.weight(.medium))
                Text("Your name stays on this device and personalizes the simulated accounts. No banking sign in is needed.").foregroundStyle(Style.gray)
                TextField("First name", text: $name).textContentType(.givenName).textInputAutocapitalization(.words)
                    .autocorrectionDisabled().focused($focused, equals: .first).padding(14)
                    .background(Style.background, in: RoundedRectangle(cornerRadius: 8)).accessibilityIdentifier("first-name")
                    .submitLabel(.next).onSubmit { focused = .middle }
                TextField("Middle name (optional)", text: $middle).textContentType(.middleName).textInputAutocapitalization(.words).autocorrectionDisabled().focused($focused, equals: .middle).padding(14).background(Style.background, in: RoundedRectangle(cornerRadius: 8)).accessibilityIdentifier("middle-name").submitLabel(.next).onSubmit { focused = .last }
                TextField("Last name", text: $last).textContentType(.familyName).textInputAutocapitalization(.words).autocorrectionDisabled().focused($focused, equals: .last).padding(14).background(Style.background, in: RoundedRectangle(cornerRadius: 8)).accessibilityIdentifier("last-name")
                    .submitLabel(.continue).onSubmit { store.completeOnboarding(name, lastName: last, middleName: middle) }
                if let error = store.onboardingError { Text(error).font(.footnote).foregroundStyle(Style.error).accessibilityIdentifier("onboarding-error") }
                PrimaryButton(title: "Continue") { focused = nil; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil); store.completeOnboarding(name, lastName: last, middleName: middle) }.accessibilityIdentifier("enter-demo")
                Text("An independent hackathon simulation, not affiliated with Chase or Zelle. All payments and notifications are simulated. No real money moves.").font(.footnote).foregroundStyle(Style.gray)
            }.padding(28).padding(.top, 48)
        }.background(.white).environment(\.colorScheme, .light).preferredColorScheme(.light)
            .onAppear { name = store.state.profile?.firstName ?? ""; middle = store.state.profile?.middleName ?? ""; last = store.state.profile?.lastName ?? "" }
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = nil; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }.accessibilityIdentifier("keyboard-done") } }
    }
}
struct BottomBar: View {
    @Environment(DemoStore.self) private var store
    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                Button { store.tab = tab } label: {
                    VStack(spacing: 3) { Image(systemName: tab.icon).font(.system(size: 20)); Text(tab.rawValue).font(.system(size: 9)) }
                        .frame(maxWidth: .infinity).frame(height: 50).foregroundStyle(store.tab == tab ? Style.blue : Style.gray)
                }.accessibilityIdentifier("tab-\(tab.rawValue)")
            }
        }.padding(.horizontal, 6).background(.white, in: Capsule()).shadow(color: .black.opacity(0.04), radius: 12, y: 5)
            .padding(.horizontal, 3).padding(.bottom, 3).background(Style.background.opacity(0.9))
    }
}
struct MoreView: View {
    @Environment(DemoStore.self) private var store
    @State private var reset = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("More").font(.largeTitle.bold()); Text("Chase Demo").font(.title2)
            Text("An independent hackathon simulation, not affiliated with Chase or Zelle. Names, recipients and activity stay on this device. No real payments, notifications, contact discovery or analytics.").foregroundStyle(Style.gray)
            MenuRow(title: "Simulated activity", icon: "list.bullet.rectangle") { store.sheet = .activity }
            MenuRow(title: "Personal details", icon: "person.crop.circle") { store.sheet = .profile }
            Button("Reset demo", role: .destructive) { reset = true }.accessibilityIdentifier("reset-demo")
            Text("Reset restores sample recipients and your saved starting balances, clears activity, and keeps your name and account suffixes.").font(.footnote).foregroundStyle(Style.gray)
            Spacer()
        }.padding(20).confirmationDialog("Restore sample recipients and clear simulated activity?", isPresented: $reset, titleVisibility: .visible) {
            Button("Reset demo now", role: .destructive) { store.reset() }
        }
    }
}
