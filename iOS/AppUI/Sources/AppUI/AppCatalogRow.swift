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
            HStack(spacing: AppLayout.gap) { details; Spacer(minLength: AppLayout.gap); controls.fixedSize(horizontal: true, vertical: false) }
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                details
                HStack { Spacer(minLength: 0); controls }
            }
        }
        .padding(.horizontal, AppLayout.gap).padding(.vertical, AppLayout.mediumGap)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.radius))
    }
    private var details: some View {
        HStack(spacing: AppLayout.gap) {
            photo.frame(width: AppLayout.thumbnailSize, height: AppLayout.thumbnailSize)
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Text(name).font(AppTypography.body.weight(.medium))
                Text(price).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
            }.frame(minWidth: AppCatalogLayout.minimumDetailsWidth, alignment: .leading)
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

private enum AppCatalogLayout {
    static let minimumDetailsWidth: CGFloat = 72
}
