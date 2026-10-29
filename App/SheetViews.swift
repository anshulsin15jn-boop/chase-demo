import SwiftUI
import DemoCore

struct DemoSheetView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let sheet: DemoSheet
    var body: some View {
        NavigationStack {
            Group {
                switch sheet {
                case .information: ScrollView { VStack(alignment: .leading, spacing: 20) { Text(store.infoTitle).font(.title2.bold()); Text(store.infoText); Text("Independent hackathon simulation").font(.footnote).foregroundStyle(Style.gray) }.padding(24) }.navigationTitle("Demo information")
                case .add: AddRecipientView()
                case .profile: ProfileSettingsView()
                case .transfer: DemoTransferView()
                case .qr: VStack(spacing: 24) {
                    Image(systemName: "qrcode.viewfinder").font(.system(size: 120, weight: .ultraLight)); Text("Simulated QR scanner").font(.title2)
                    Text("No camera access is requested. Select the sample code to use a demonstration recipient.").multilineTextAlignment(.center)
                    PrimaryButton(title: "Use sample recipient") { dismiss(); store.select(store.recipients[0]) }
                }.padding(24).navigationTitle("Scan QR code")
                case .account: List(store.ledger.accounts) { account in
                    Button { store.draft?.accountID = account.id; dismiss() } label: {
                        HStack { VStack(alignment: .leading) { Text(store.accountLabel(account)); Text(Demo.money(account.cents)).font(.footnote).foregroundStyle(Style.gray) }; Spacer(); if store.draft?.accountID == account.id { Image(systemName: "checkmark") } }
                    }
                }.navigationTitle("Pay from")
                case .date: DateSelectionSheet()
                case .frequency: List(Frequency.allCases, id: \.self) { frequency in
                    Button { store.draft?.frequency = frequency; dismiss() } label: { HStack { Text(frequency.rawValue); Spacer(); if store.draft?.frequency == frequency { Image(systemName: "checkmark") } } }
                }.navigationTitle("Repeat payment")
                case .activity: ActivityList().navigationTitle("Demo activity")
                }
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
        }.presentationDragIndicator(.visible).environment(\.colorScheme, .light).preferredColorScheme(.light)
    }
}
struct DateSelectionSheet: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            HStack {
                Button("Today") { store.selectToday() }; Spacer()
                Button("In 2 days") { store.selectDate(store.calendar.date(byAdding: .day, value: 2, to: store.now)!) }
            }.padding(.bottom, 12)
            DatePicker("Send on", selection: Binding(get: { store.draft?.effectiveDate(now: store.now, calendar: store.calendar) ?? store.now }, set: { store.selectDate($0) }), in: store.calendar.startOfDay(for: store.now)..., displayedComponents: .date)
                .datePickerStyle(.graphical).environment(\.calendar, store.calendar).environment(\.timeZone, store.calendar.timeZone)
            PrimaryButton(title: "Use selected date") { dismiss() }
        }.padding(20).navigationTitle("Send on").onAppear { store.refreshDay() }
    }
}
struct AddRecipientView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var number = ""
    @State private var email = ""
    @State private var error: String?
    @State private var saving = false
    @FocusState private var field: Field?
    enum Field { case name, number, email }
    var body: some View {
        Form {
            Section { Text("Create a local demonstration recipient with a name, a 9 or 10 digit number, or an email. Nothing is sent externally.").font(.footnote) }
            Section("Recipient details") {
                TextField("Name (optional)", text: $name).textContentType(.name).autocorrectionDisabled().focused($field, equals: .name).accessibilityIdentifier("new-name")
                TextField("Number, 9 or 10 digits (optional)", text: $number).keyboardType(.numberPad).focused($field, equals: .number).accessibilityIdentifier("new-number")
                TextField("Email (optional)", text: $email).keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().focused($field, equals: .email).accessibilityIdentifier("new-email")
            }
            if let error { Text(error).foregroundStyle(Style.error).font(.footnote).accessibilityIdentifier("recipient-error") }
            Button("Add demo recipient") {
                guard !saving else { return }; saving = true; field = nil
                do { try store.addRecipient(name: name, number: number, email: email); dismiss() }
                catch { self.error = (error as? InputError)?.rawValue ?? "The recipient could not be saved locally. Please try again."; saving = false }
            }.disabled(saving).accessibilityIdentifier("save-recipient")
        }.navigationTitle("Add recipient").toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { field = nil }.accessibilityIdentifier("keyboard-done") } }
    }
}
struct ActivityList: View {
    @Environment(DemoStore.self) private var store
    var scheduledOnly = false
    var payments: [Payment] { store.ledger.payments.filter { !scheduledOnly || $0.scheduled } }
    var body: some View {
        if payments.isEmpty { ContentUnavailableView("No demo payments yet", systemImage: "list.bullet.rectangle", description: Text("Your simulated payments will appear here.")) }
        else {
            List(payments) { payment in
                VStack(alignment: .leading, spacing: 7) {
                    HStack { Text(payment.recipient.displayName).font(.headline); Spacer(); Text(Demo.money(payment.cents)) }
                    if !payment.recipient.subtitle.isEmpty { Text(payment.recipient.subtitle).font(.footnote) }
                    Text("\(payment.scheduled ? "Scheduled" : "Completed") • \(store.dateLabel(payment))").font(.subheadline).foregroundStyle(Style.gray)
                    Text(payment.account.label).font(.footnote).foregroundStyle(Style.gray)
                    Text("Sending as \(payment.sender.uppercased())").font(.footnote).foregroundStyle(Style.gray)
                    if !payment.message.isEmpty { Text(payment.message).font(.footnote).accessibilityIdentifier("activity-message") }
                    if payment.frequency != .once { Text("\(payment.frequency.rawValue) • demo only").font(.footnote) }
                }.accessibilityElement(children: .contain).accessibilityIdentifier("activity-\(payment.id)")
            }
        }
    }
}
