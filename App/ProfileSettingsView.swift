import SwiftUI
import DemoCore

struct ProfileSettingsView: View {
    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var first = ""
    @State private var middle = ""
    @State private var last = ""
    @State private var error: String?
    @FocusState private var field: Field?
    private enum Field { case first, middle, last }
    var body: some View {
        Form {
            Section { Text("Your name stays on this device. Updating it changes the simulated sender and current account labels. Historical payments keep their original details.").font(.footnote) }
            Section("Name") {
                TextField("First name", text: $first).textContentType(.givenName).focused($field, equals: .first).accessibilityIdentifier("profile-first-name")
                TextField("Middle name (optional)", text: $middle).textContentType(.middleName).focused($field, equals: .middle).accessibilityIdentifier("profile-middle-name")
                TextField("Last name", text: $last).textContentType(.familyName).focused($field, equals: .last).accessibilityIdentifier("profile-last-name")
            }.textInputAutocapitalization(.words).autocorrectionDisabled()
            if let error { Text(error).foregroundStyle(Style.error).accessibilityIdentifier("profile-error") }
            Button("Save name") {
                field = nil
                do { try store.updateProfile(firstName: first, lastName: last, middleName: middle); dismiss() }
                catch { self.error = (error as? InputError)?.rawValue ?? "Your name could not be saved locally. Please try again." }
            }.accessibilityIdentifier("save-profile")
        }.navigationTitle("Personal details").onAppear {
            first = store.state.profile?.firstName ?? ""; middle = store.state.profile?.middleName ?? ""; last = store.state.profile?.lastName ?? ""
        }.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { field = nil }.accessibilityIdentifier("keyboard-done") } }
    }
}
