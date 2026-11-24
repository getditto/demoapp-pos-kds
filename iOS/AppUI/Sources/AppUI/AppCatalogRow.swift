import SwiftUI

public struct AppCatalogRow<Photo: View, Controls: View>: View {
    private let name: String
    private let price: String
    private let photo: Photo
    private let controls: Controls
    public init(name: String, price: String, @ViewBuilder photo: () -> Photo, @ViewBuilder controls: () -> Controls) {
        self.name = name; self.price = price; self.photo = photo(); self.controls = controls()
    }
    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { details; Spacer(minLength: 8); controls.fixedSize(horizontal: true, vertical: false) }
            VStack(alignment: .leading, spacing: 12) {
                details
                HStack { Spacer(minLength: 0); controls }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.radius))
    }
    private var details: some View {
        HStack(spacing: 8) {
            photo.frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(AppTypography.body.weight(.medium))
                Text(price).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
            }.frame(minWidth: 72, alignment: .leading)
        }
    }
}

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
            step("minus", enabled: canDecrement, action: decrement)
            value
            step("plus", enabled: canIncrement, action: increment)
        }
    }
    private func step(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { AppIcon(icon, size: 22).frame(width: AppLayout.controlHeight, height: AppLayout.controlHeight) }
            .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.38)
            .accessibilityLabel(icon == "minus" ? "Decrease quantity" : "Increase quantity")
    }
}
