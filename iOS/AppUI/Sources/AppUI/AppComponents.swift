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
            .opacity(configuration.isPressed ? AppLayout.pressedOpacity : 1)
    }
    private var foreground: Color { kind == .primary ? AppColors.onAccent : kind == .destructive ? AppColors.critical : AppColors.text }
    private var background: Color { kind == .primary ? AppColors.accent : kind == .text ? .clear : AppColors.surface }
}

public enum AppSurfaceStyle {
    case standard, outlined, compact
    var cornerRadius: CGFloat { self == .compact ? AppLayout.buttonRadius : AppLayout.radius }
    var borderColor: Color { self == .outlined ? AppColors.subtleBorder : .clear }
}

public struct AppSurface<Content: View>: View {
    private let style: AppSurfaceStyle
    private let contentPadding: EdgeInsets
    private let content: Content
    public init(style: AppSurfaceStyle = .standard,
                contentPadding: EdgeInsets = EdgeInsets(top: AppLayout.padding, leading: AppLayout.padding, bottom: AppLayout.padding, trailing: AppLayout.padding),
                @ViewBuilder content: () -> Content) {
        self.style = style; self.contentPadding = contentPadding; self.content = content()
    }
    public var body: some View {
        content.padding(contentPadding).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: style.cornerRadius).strokeBorder(style.borderColor, lineWidth: AppLayout.borderWidth))
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
        HStack(spacing: AppLayout.mediumGap) {
            if let icon { AppIcon(icon) }
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                if let eyebrow { Text(eyebrow).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText) }
                Text(title).font(AppTypography.body)
                if let detail { Text(detail).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText) }
            }
            Spacer(minLength: AppLayout.gap)
            trailing
        }
        .frame(minHeight: AppRowLayout(eyebrow: eyebrow).minimumHeight)
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
            HStack(spacing: AppLayout.mediumGap) {
                Text(title).font(AppTypography.body)
                Spacer(minLength: AppLayout.gap)
                if selected { AppIcon("check", size: AppLayout.actionIconSize) }
            }
            .padding(.horizontal, AppLayout.mediumGap).padding(.vertical, AppLayout.gap)
            .frame(minHeight: AppLayout.controlHeight)
            .background(selected ? AppColors.selection : .clear, in: RoundedRectangle(cornerRadius: AppLayout.smallRadius))
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
            content.padding(AppLayout.mediumGap).frame(minHeight: AppLayout.controlHeight)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).strokeBorder(error == nil ? AppColors.border : AppColors.critical))
            if let error { Text(error).font(AppTypography.caption).foregroundStyle(AppColors.critical).accessibilityLabel("Error: \(error)") }
        }
    }
}

public struct AppHeader<Trailing: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var titleLineHeight = AppLayout.titleLineHeight
    private let title: String
    private let trailing: Trailing
    public init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.trailing = trailing()
    }
    private var layout: AppHeaderLayout { AppHeaderLayout(sizeClass: sizeClass) }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppLayout.padding) {
                Image("ditto-symbol", bundle: .module).resizable().scaledToFit()
                    .frame(width: layout.symbolWidth, height: layout.symbolHeight)
                    .accessibilityLabel("Ditto")
                if layout.expanded { titleText }
                Spacer(minLength: AppLayout.gap)
                trailing
            }.frame(minHeight: layout.height)
            if !layout.expanded { titleText.frame(minHeight: AppLayout.pageTitleHeight, alignment: .leading) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.vertical, layout.verticalPadding)
        .background(AppColors.background)
    }
    private var titleText: some View {
        Text(title).font(AppTypography.pageTitle)
            .frame(minHeight: titleLineHeight, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

public extension AppHeader where Trailing == EmptyView {
    init(_ title: String) { self.init(title) { EmptyView() } }
}

public struct AppEmptyState: View {
    private let title: String
    private let message: String
    private let icon: String
    private let prominent: Bool
    public init(_ title: String, message: String, icon: String, prominent: Bool = false) {
        self.title = title; self.message = message; self.icon = icon; self.prominent = prominent
    }
    public var body: some View {
        VStack(spacing: 12) {
            AppIcon(icon, size: prominent ? 40 : 56).foregroundStyle(prominent ? AppColors.success : AppColors.secondaryText)
            Text(title).font(prominent ? AppTypography.title : AppTypography.heading)
            Text(message).font(prominent ? AppTypography.body : AppTypography.caption).foregroundStyle(AppColors.secondaryText)
        }
        .multilineTextAlignment(.center).padding(AppLayout.sectionGap)
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
