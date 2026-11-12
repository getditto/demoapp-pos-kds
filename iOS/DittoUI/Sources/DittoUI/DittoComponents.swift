import SwiftUI

public struct DittoButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, destructive, text }
    @Environment(\.isEnabled) private var isEnabled
    private let kind: Kind
    public init(_ kind: Kind = .primary) { self.kind = kind }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(DittoTypography.action).textCase(.uppercase)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DittoLayout.padding)
            .frame(minHeight: DittoLayout.controlHeight)
            .foregroundStyle(isEnabled ? foreground : DittoColors.disabledText)
            .background(isEnabled ? background : kind == .text ? .clear : DittoColors.disabled,
                        in: RoundedRectangle(cornerRadius: DittoLayout.buttonRadius))
            .overlay(RoundedRectangle(cornerRadius: DittoLayout.buttonRadius)
                .strokeBorder(kind == .secondary ? DittoColors.border : .clear))
            .contentShape(RoundedRectangle(cornerRadius: DittoLayout.buttonRadius))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
    private var foreground: Color { kind == .primary ? DittoColors.onAccent : kind == .destructive ? DittoColors.critical : DittoColors.text }
    private var background: Color { kind == .primary ? DittoColors.accent : kind == .text ? .clear : DittoColors.surface }
}

public struct DittoSurface<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.padding(DittoLayout.padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(DittoColors.surface, in: RoundedRectangle(cornerRadius: DittoLayout.radius))
    }
}

public struct DittoRow<Trailing: View>: View {
    private let title: String
    private let eyebrow: String?
    private let detail: String?
    private let icon: String?
    private let outlined: Bool
    private let trailing: Trailing
    public init(_ title: String, eyebrow: String? = nil, detail: String? = nil, icon: String? = nil, outlined: Bool = false, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.eyebrow = eyebrow; self.detail = detail; self.icon = icon; self.outlined = outlined; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 12) {
            if let icon { DittoIcon(icon) }
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow { Text(eyebrow).font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText) }
                Text(title).font(DittoTypography.body)
                if let detail { Text(detail).font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText) }
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: eyebrow == nil ? 32 : DittoLayout.controlHeight)
        .padding(DittoLayout.padding)
        .background(DittoColors.surface, in: RoundedRectangle(cornerRadius: DittoLayout.radius))
        .overlay(RoundedRectangle(cornerRadius: DittoLayout.radius).strokeBorder(outlined ? DittoColors.border : .clear))
        .contentShape(Rectangle())
    }
}

public struct DittoChoiceRow: View {
    private let title: String
    private let selected: Bool
    private let action: () -> Void
    public init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title; self.selected = selected; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(DittoTypography.body)
                Spacer(minLength: 8)
                if selected { DittoIcon("check", size: 22) }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(minHeight: DittoLayout.controlHeight)
            .background(selected ? DittoColors.selection : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

public struct DittoField<Content: View>: View {
    private let label: String
    private let error: String?
    private let content: Content
    public init(_ label: String, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.error = error; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: DittoLayout.gap) {
            Text(label).font(DittoTypography.caption)
            content.padding(12).frame(minHeight: DittoLayout.controlHeight)
                .background(DittoColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(error == nil ? DittoColors.border : DittoColors.critical))
            if let error { Text(error).font(DittoTypography.caption).foregroundStyle(DittoColors.critical).accessibilityLabel("Error: \(error)") }
        }
    }
}

public struct DittoHeader: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var titleLineHeight = 41
    private let title: String
    private let location: String?
    public init(_ title: String, location: String? = nil) { self.title = title; self.location = location }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Image("ditto-symbol", bundle: .module).resizable().scaledToFit()
                    .frame(width: sizeClass == .regular ? 28 : 24.5, height: sizeClass == .regular ? 32 : 28)
                    .accessibilityLabel("Ditto")
                if sizeClass == .regular { titleText }
                Spacer(minLength: 8)
                if let location, !location.isEmpty {
                    HStack(spacing: 6) {
                        DittoIcon("map-pin", size: 18)
                        Text(location).font(DittoTypography.footnote)
                    }.foregroundStyle(DittoColors.secondaryText)
                }
            }.frame(minHeight: sizeClass == .regular ? 56 : 48)
            if sizeClass != .regular { titleText.frame(minHeight: 64, alignment: .leading) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, sizeClass == .regular ? 20 : DittoLayout.padding)
        .padding(.vertical, sizeClass == .regular ? DittoLayout.padding : 0)
        .background(DittoColors.background)
    }
    private var titleText: some View {
        Text(title).font(DittoTypography.pageTitle)
            .frame(minHeight: titleLineHeight, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

public struct DittoEmptyState: View {
    private let title: String
    private let message: String
    private let icon: String
    private let prominent: Bool
    public init(_ title: String, message: String, icon: String, prominent: Bool = false) {
        self.title = title; self.message = message; self.icon = icon; self.prominent = prominent
    }
    public var body: some View {
        VStack(spacing: 12) {
            DittoIcon(icon, size: prominent ? 40 : 56).foregroundStyle(prominent ? DittoColors.success : DittoColors.secondaryText)
            Text(title).font(prominent ? DittoTypography.title : DittoTypography.heading)
            Text(message).font(prominent ? DittoTypography.body : DittoTypography.caption).foregroundStyle(DittoColors.secondaryText)
        }
        .multilineTextAlignment(.center).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct DittoWell<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.padding(24).frame(maxWidth: .infinity, minHeight: 160)
            .background(DittoColors.background, in: RoundedRectangle(cornerRadius: DittoLayout.radius))
            .overlay(RoundedRectangle(cornerRadius: DittoLayout.radius).strokeBorder(DittoColors.subtleBorder))
    }
}
