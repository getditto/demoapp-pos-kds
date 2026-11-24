import SwiftUI

// numberPad has no return key. The native accessory and Escape share the caller's draft actions.
public struct AppNumberField: UIViewRepresentable {
    @Binding private var text: String
    private let isValid: Bool
    private let onDone: () -> Void
    private let onCancel: () -> Void
    private let onFocus: () -> Void
    public init(text: Binding<String>, isValid: Bool, onDone: @escaping () -> Void, onCancel: @escaping () -> Void, onFocus: @escaping () -> Void) {
        _text = text; self.isValid = isValid; self.onDone = onDone; self.onCancel = onCancel; self.onFocus = onFocus
    }
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    public func makeUIView(context: Context) -> UITextField {
        _ = BrandResources.registeredFonts
        let field = CancelableNumberField()
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.adjustsFontForContentSizeCategory = true
        field.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: "GeistMono-Regular", size: 17)!)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.cancel = { context.coordinator.parent.onCancel() }
        let toolbar = UIToolbar()
        toolbar.items = [.flexibleSpace(), context.coordinator.doneButton]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        return field
    }
    public func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
        field.textColor = UIColor(isValid ? AppColors.text : AppColors.critical)
        context.coordinator.doneButton.isEnabled = isValid
    }
    public final class Coordinator: NSObject, UITextFieldDelegate {
        fileprivate var parent: AppNumberField
        fileprivate lazy var doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        fileprivate init(_ parent: AppNumberField) { self.parent = parent }
        @objc fileprivate func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        @objc private func done() { if parent.isValid { parent.onDone() } }
        public func textFieldShouldReturn(_ textField: UITextField) -> Bool { done(); return false }
        public func textFieldDidBeginEditing(_ textField: UITextField) { parent.onFocus() }
        public func textFieldDidEndEditing(_ textField: UITextField) { parent.onCancel() }
    }
}

private final class CancelableNumberField: UITextField {
    var cancel: (() -> Void)?
    private var requestedFocus = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !requestedFocus else { return }
        requestedFocus = true
        DispatchQueue.main.async { [weak self] in
            guard let self, window != nil else { return }
            becomeFirstResponder(); selectAll(nil)
        }
    }
    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(cancelDraft))]
    }
    @objc private func cancelDraft() { cancel?(); resignFirstResponder() }
}
