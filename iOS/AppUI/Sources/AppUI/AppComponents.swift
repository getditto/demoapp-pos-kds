import SwiftUI

public struct AppButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, destructive, text }
    @Environment(\.isEnabled) private var isEnabled
    private let kind: Kind
    public init(_ kind: Kind = .primary) { self.kind = kind }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(AppTypography.action).textCase(.uppercase)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppLayout.padding)
            .frame(minHeight: AppLayout.controlHeight)
            .foregroundStyle(isEnabled ? foreground : AppColors.disabledText)
            .background(isEnabled ? background : kind == .text ? .clear : AppColors.disabled,
                        in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .overlay(RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                .strokeBorder(kind == .secondary ? AppColors.border : .clear))
            .contentShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
    private var foreground: Color { kind == .primary ? AppColors.onAccent : kind == .destructive ? AppColors.critical : AppColors.text }
    private var background: Color { kind == .primary ? AppColors.accent : kind == .text ? .clear : AppColors.surface }
}

public struct AppSurface<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.padding(AppLayout.padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.radius))
    }
}

public struct AppRow<Trailing: View>: View {
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
            if let icon { AppIcon(icon) }
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow { Text(eyebrow).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText) }
                Text(title).font(AppTypography.body)
                if let detail { Text(detail).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText) }
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: eyebrow == nil ? 32 : AppLayout.controlHeight)
        .padding(AppLayout.padding)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.radius))
        .overlay(RoundedRectangle(cornerRadius: AppLayout.radius).strokeBorder(outlined ? AppColors.border : .clear))
        .contentShape(Rectangle())
    }
}

public struct AppChoiceRow: View {
    private let title: String
    private let selected: Bool
    private let action: () -> Void
    public init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title; self.selected = selected; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(AppTypography.body)
                Spacer(minLength: 8)
                if selected { AppIcon("check", size: 22) }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(minHeight: AppLayout.controlHeight)
            .background(selected ? AppColors.selection : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

public struct AppField<Content: View>: View {
    private let label: String
    private let error: String?
    private let content: Content
    public init(_ label: String, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.error = error; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.gap) {
            Text(label).font(AppTypography.caption)
            content.padding(12).frame(minHeight: AppLayout.controlHeight)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(error == nil ? AppColors.border : AppColors.critical))
            if let error { Text(error).font(AppTypography.caption).foregroundStyle(AppColors.critical).accessibilityLabel("Error: \(error)") }
        }
    }
}

public struct AppHeader: View {
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
                        AppIcon("map-pin", size: 18)
                        Text(location).font(AppTypography.footnote)
                    }.foregroundStyle(AppColors.secondaryText)
                }
            }.frame(minHeight: sizeClass == .regular ? 56 : 48)
            if sizeClass != .regular { titleText.frame(minHeight: 64, alignment: .leading) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, sizeClass == .regular ? 20 : AppLayout.padding)
        .padding(.vertical, sizeClass == .regular ? AppLayout.padding : 0)
        .background(AppColors.background)
    }
    private var titleText: some View {
        Text(title).font(AppTypography.pageTitle)
            .frame(minHeight: titleLineHeight, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

public enum AppEmptyStateStyle { case standard, success, large }

public struct AppEmptyState: View {
    private let title: String
    private let message: String
    private let icon: String
    private let style: AppEmptyStateStyle
    public init(_ title: String, message: String, icon: String, style: AppEmptyStateStyle = .standard) {
        self.title = title; self.message = message; self.icon = icon; self.style = style
    }
    public var body: some View {
        VStack(spacing: style == .large ? 16 : 12) {
            AppIcon(icon, size: style == .large ? 64 : style == .success ? 40 : 56)
                .foregroundStyle(style == .large ? AppColors.text : style == .success ? AppColors.success : AppColors.secondaryText)
            Text(title).font(style == .standard ? AppTypography.heading : AppTypography.title)
            Text(message).font(style == .standard ? AppTypography.caption : AppTypography.body).foregroundStyle(AppColors.secondaryText)
        }
        .multilineTextAlignment(.center).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct AppWell<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.padding(24).frame(maxWidth: .infinity, minHeight: 160)
            .background(AppColors.background, in: RoundedRectangle(cornerRadius: AppLayout.radius))
            .overlay(RoundedRectangle(cornerRadius: AppLayout.radius).strokeBorder(AppColors.subtleBorder))
    }
}
