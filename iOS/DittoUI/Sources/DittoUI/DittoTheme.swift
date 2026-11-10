import SwiftUI

public enum DittoColors {
    public static let background = adaptive(0xFAFAFA, 0x171717)
    public static let surface = adaptive(0xFFFFFF, 0x262626)
    public static let text = adaptive(0x0A0A0A, 0xFAFAFA)
    public static let secondaryText = adaptive(0x525252, 0xD4D4D4)
    public static let border = adaptive(0xD4D4D4, 0x525252)
    public static let accent = adaptive(0xE7EE00, 0xECF238)
    public static let onAccent = Color.black
    public static let selection = adaptive(0xFCFCDD, 0x454800)
    public static let critical = adaptive(0xC10007, 0xFF6467)
    public static let disabled = adaptive(0xE5E5E5, 0x404040)
    public static let disabledText = adaptive(0x737373, 0xA1A1A1)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

public enum DittoLayout {
    public static let gap: CGFloat = 8
    public static let padding: CGFloat = 16
    public static let radius: CGFloat = 16
    public static let buttonRadius: CGFloat = 12
    public static let controlHeight: CGFloat = 48
}

public struct DittoTheme<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.font(DittoTypography.body)
            .foregroundStyle(DittoColors.text)
            .tint(DittoColors.text)
            .background(DittoColors.background.ignoresSafeArea())
    }
}
