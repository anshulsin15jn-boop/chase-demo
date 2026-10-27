import SwiftUI
import DemoCore
struct DemoSheetView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let sheet: DemoSheet
    var body: some View {
        NavigationStack {
            Group { switch sheet {
            case .information: ScrollView { VStack(alignment: .leading, spacing: 20) { Text(store.infoTitle).font(.title2.bold()); Text(store.infoText); Text("Hackathon demonstration ? Fictional data only").font(.footnote).foregroundStyle(Style.gray) }.padding(24) }.navigationTitle("Demo information")
            case .add: AddRecipientView()
            case .qr: VStack(spacing: 24) { Image(systemName: "qrcode.viewfinder").font(.system(size: 120, weight: .ultraLight)); Text("Simulated QR scanner").font(.title2); Text("No camera access is requested. Select the sample code to use a fictional recipient.").multilineTextAlignment(.center); PrimaryButton(title: "Use sample recipient") { dismiss(); store.select(store.recipients[0]) } }.padding(24).navigationTitle("Scan QR code")
            case .account: List(store.ledger.accounts) { account in Button { store.draft?.accountID = account.id; dismiss() } label: { HStack { VStack(alignment: .leading) { Text(account.label); Text(Demo.money(account.cents)).font(.footnote).foregroundStyle(Style.gray) }; Spacer(); if store.draft?.accountID == account.id { Image(systemName: "checkmark") } } } }.navigationTitle("Pay from")
            case .date: VStack { Text("Demo clock: \(Demo.day(store.now))").font(.footnote).foregroundStyle(Style.gray); DatePicker("Send on", selection: Binding(get: { store.draft?.date ?? store.now }, set: { store.draft?.date = $0 }), in: store.now..., displayedComponents: .date).datePickerStyle(.graphical).environment(\.timeZone, Demo.calendar.timeZone); PrimaryButton(title: "Use selected date") { dismiss() } }.padding(20).navigationTitle("Send on")
            case .frequency: List(Frequency.allCases, id: \.self) { frequency in Button { store.draft?.frequency = frequency; dismiss() } label: { HStack { Text(frequency.rawValue); Spacer(); if store.draft?.frequency == frequency { Image(systemName: "checkmark") } } } }.navigationTitle("Repeat payment")
            case .activity: ActivityList().navigationTitle("Demo activity")
            } }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
        }.presentationDragIndicator(.visible)
    }
}
struct AddRecipientView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var contact = ""
    @State private var error = ""
    var body: some View {
        Form {
            Section { Text("Use an invented name and a 202 555 0100?0199 phone number or example.com email. Do not enter personal information.").font(.footnote) }
            Section("Fictional recipient") { TextField("Fictional name", text: $name).accessibilityIdentifier("new-name"); TextField("Demo phone or email", text: $contact).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("new-contact") }
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            Button("Add demo recipient") {
                let n = name.trimmingCharacters(in: .whitespacesAndNewlines); let c = contact.trimmingCharacters(in: .whitespacesAndNewlines)
                guard (2...60).contains(n.count), n.allSatisfy({ $0.isLetter || " '-".contains($0) }) else { error = "Enter a fictional name between 2 and 60 characters."; return }
                guard Demo.validContact(c) else { error = "Use a reserved 202 555 0100?0199 number or an example.com email."; return }
                guard !store.recipients.contains(where: { $0.contact.caseInsensitiveCompare(c) == .orderedSame }) else { error = "This demo recipient already exists."; return }
                store.recipients.append(Recipient(id: UUID().uuidString, name: n, contact: c)); store.persist(); dismiss()
            }.accessibilityIdentifier("save-recipient")
        }.navigationTitle("Add recipient")
    }
}
struct ActivityList: View {
    @Environment(DemoStore.self) private var store
    var scheduledOnly = false
    var payments: [Payment] { store.ledger.payments.filter { !scheduledOnly || $0.scheduled } }
    var body: some View {
        if payments.isEmpty { ContentUnavailableView("No demo payments yet", systemImage: "list.bullet.rectangle", description: Text("Your simulated payments will appear here.")) }
        else { List(payments) { payment in VStack(alignment: .leading, spacing: 7) { HStack { Text(payment.recipient.name).font(.headline); Spacer(); Text(Demo.money(payment.cents)) }; Text("\(payment.scheduled ? "Scheduled" : "Completed") ? \(Demo.day(payment.date))").font(.subheadline).foregroundStyle(Style.gray); if !payment.message.isEmpty { Text(payment.message).font(.footnote) }; if payment.frequency != .once { Text("\(payment.frequency.rawValue) ? demo only").font(.footnote) } }.accessibilityIdentifier("activity-\(payment.id)") } }
    }
}
