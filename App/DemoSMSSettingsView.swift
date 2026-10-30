import SwiftUI
import DemoCore

struct DemoSMSSettingsView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var endpoint = MessagingEndpoint.address
    @State private var token = ""
    @State private var consent = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Optional demo texts") {
                    Text("When enabled, submitted demo payments send the snapshot's sender name, recipient name, number and amount to your relay and SMS provider. Only designated test recipients who agreed to receive these clearly labeled simulation texts may be allowlisted. No money moves.")
                    Text(store.sendsDemoMessages ? "Configured on this device; delivery is not verified." : "SMS is off.")
                }
                Section("Private relay configuration") {
                    TextField("https://your-relay.example.com/send", text: $endpoint)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Relay token (at least 32 characters)", text: $token)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("Use the relay token, never your SMS provider credentials. It is stored in this device's Keychain.").font(.footnote)
                    Toggle("My test recipients opted in", isOn: $consent)
                    if let error { Text(error).foregroundStyle(.red) }
                    Button("Enable demo SMS") {
                        guard MessagingEndpoint.save(address: endpoint, token: token) else {
                            error = "Enter an HTTPS /send URL and a valid relay token. Secure storage must be available."
                            return
                        }
                        store.configureMessaging(MessagingEndpoint.delivery)
                        token = ""
                        dismiss()
                    }.disabled(!consent)
                    Button("Turn off SMS", role: .destructive) {
                        MessagingEndpoint.disable()
                        store.configureMessaging(DisabledDemoMessageDelivery())
                        token = ""
                        dismiss()
                    }
                    Text("Turning off stops future requests. A request already submitted cannot be recalled. This screen sends no test message.").font(.footnote)
                }
            }.navigationTitle("Demo SMS")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
