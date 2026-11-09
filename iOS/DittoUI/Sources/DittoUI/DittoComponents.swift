import SwiftUI

public struct DittoButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, destructive }
    @Environment(\.isEnabled) private var isEnabled
    private let kind: Kind
    public init(_ kind: Kind = .primary) { self.kind = kind }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(DittoTypography.action).textCase(.uppercase)
            .padding(.horizontal, DittoLayout.padding)
            .frame(minHeight: DittoLayout.controlHeight)
            .foregroundStyle(isEnabled ? foreground : DittoColors.disabledText)
            .background(isEnabled ? background : DittoColors.disabled,
                        in: RoundedRectangle(cornerRadius: DittoLayout.radius))
            .overlay(RoundedRectangle(cornerRadius: DittoLayout.radius)
                .strokeBorder(kind == .secondary ? DittoColors.border : .clear))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
    private var foreground: Color { kind == .primary ? DittoColors.onAccent : kind == .destructive ? DittoColors.critical : DittoColors.text }
    private var background: Color { kind == .primary ? DittoColors.accent : DittoColors.surface }
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
    private let detail: String?
    private let icon: String
    private let trailing: Trailing
    public init(_ title: String, detail: String? = nil, icon: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.detail = detail; self.icon = icon; self.trailing = trailing()
    }
    public var body: some View {
        HStack(spacing: 12) {
            DittoIcon(icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(DittoTypography.body)
                if let detail { Text(detail).font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText) }
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: DittoLayout.controlHeight)
        .padding(DittoLayout.padding)
        .background(DittoColors.surface, in: RoundedRectangle(cornerRadius: DittoLayout.radius))
        .contentShape(Rectangle())
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
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image("ditto-symbol", bundle: .module).resizable().scaledToFit()
                    .frame(width: sizeClass == .regular ? 28 : 24.5, height: sizeClass == .regular ? 32 : 28)
                    .accessibilityLabel("Ditto")
                Spacer(minLength: 8)
                if let location, !location.isEmpty {
                    HStack(spacing: 6) {
                        DittoIcon("map-pin", size: 18)
                        Text(location).font(DittoTypography.caption)
                    }.foregroundStyle(DittoColors.secondaryText)
                }
            }
            Text(title).font(DittoTypography.pageTitle)
                .frame(minHeight: titleLineHeight, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, sizeClass == .regular ? 20 : DittoLayout.padding)
        .padding(.vertical, DittoLayout.padding)
    }
}

public struct DittoEmptyState: View {
    private let title: String
    private let message: String
    private let icon: String
    public init(_ title: String, message: String, icon: String) { self.title = title; self.message = message; self.icon = icon }
    public var body: some View {
        VStack(spacing: 12) {
            DittoIcon(icon, size: 56).foregroundStyle(DittoColors.secondaryText)
            Text(title).font(DittoTypography.heading)
            Text(message).font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText)
        }
        .multilineTextAlignment(.center).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct DittoWell<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.frame(maxWidth: .infinity, minHeight: 240)
            .background(DittoColors.disabled.opacity(0.4), in: RoundedRectangle(cornerRadius: DittoLayout.radius))
            .overlay(RoundedRectangle(cornerRadius: DittoLayout.radius).strokeBorder(DittoColors.border, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
    }
}
