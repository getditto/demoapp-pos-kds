import SwiftUI

public struct AppCounter<Value: View>: View {
    private let canDecrement: Bool
    private let canIncrement: Bool
    private let decrement: () -> Void
    private let increment: () -> Void
    private let value: Value
    public init(canDecrement: Bool, canIncrement: Bool = true, decrement: @escaping () -> Void, increment: @escaping () -> Void, @ViewBuilder value: () -> Value) {
        self.canDecrement = canDecrement; self.canIncrement = canIncrement
        self.decrement = decrement; self.increment = increment; self.value = value()
    }
    public var body: some View {
        HStack(spacing: AppLayout.gap) {
            step("minus", label: "Decrease quantity", enabled: canDecrement, action: decrement)
            value
            step("plus", label: "Increase quantity", enabled: canIncrement, action: increment)
        }
    }
    private func step(_ icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { AppIcon(icon, size: AppLayout.actionIconSize).frame(width: AppLayout.controlHeight, height: AppLayout.controlHeight) }
            .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : AppLayout.disabledOpacity)
            .accessibilityLabel(label)
    }
}
