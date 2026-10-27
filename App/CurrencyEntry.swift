import SwiftUI
import UIKit
import DemoCore

struct CurrencyEntry: UIViewRepresentable {
    @Binding var value: CurrencyInput
    var invalidInput: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator; field.keyboardType = .numberPad
        field.font = .systemFont(ofSize: 42, weight: .light); field.textColor = UIColor(white: 0.07, alpha: 1)
        field.adjustsFontSizeToFitWidth = true; field.minimumFontSize = 22
        field.textAlignment = .center; field.tintColor = .systemBlue
        field.accessibilityIdentifier = "amount-field"; field.accessibilityLabel = "Amount"
        field.text = value.formatted
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.done))
        done.accessibilityIdentifier = "keyboard-done"
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), done]; field.inputAccessoryView = toolbar
        context.coordinator.field = field
        return field
    }
    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != value.formatted { field.text = value.formatted }
    }
    @MainActor final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyEntry
        weak var field: UITextField?
        init(_ parent: CurrencyEntry) { self.parent = parent }
        @objc func done() { field?.resignFirstResponder() }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            var next = parent.value
            do {
                let allSelected = range.length == (textField.text ?? "").utf16.count
                if string.isEmpty {
                    if allSelected { next = CurrencyInput() } else { next.backspace() }
                } else if allSelected { try next.replace(with: string) }
                else { try next.append(string) }
                parent.value = next; textField.text = next.formatted
                let end = textField.endOfDocument; textField.selectedTextRange = textField.textRange(from: end, to: end)
            } catch { parent.invalidInput((error as? InputError)?.rawValue ?? "Use digits 0–9 only.") }
            return false
        }
    }
}
