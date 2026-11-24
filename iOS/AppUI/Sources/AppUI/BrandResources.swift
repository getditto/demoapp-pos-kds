import CoreText
import SwiftUI

public enum BrandResources {
    public static let bundle = Bundle.module

    static let registeredFonts: Void = {
        for name in ["ChakraPetch-Regular", "Geist", "GeistMono"] {
            let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "BrandResources/Fonts")!
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}

public enum AppTypography {
    public static var pageTitle: Font { font("ChakraPetch-Regular", size: 34, relativeTo: .largeTitle) }
    public static var body: Font { font("Geist-Regular", size: 17, relativeTo: .body) }
    public static var title: Font { font("Geist-Regular", size: 22, relativeTo: .title2).weight(.medium) }
    public static var heading: Font { font("Geist-Regular", size: 20, relativeTo: .title3) }
    public static var caption: Font { font("Geist-Regular", size: 12, relativeTo: .caption) }
    public static var footnote: Font { font("Geist-Regular", size: 13, relativeTo: .footnote) }
    public static var action: Font { font("GeistMono-Regular", size: 14, relativeTo: .callout) }
    public static let quantitySize: CGFloat = 17
    public static var quantity: Font { font("GeistMono-Regular", size: quantitySize, relativeTo: .body).weight(.medium) }

    public static func quantityInputFont(size: CGFloat) -> UIFont {
        _ = BrandResources.registeredFonts
        return UIFont(name: "GeistMono-Regular", size: size)!
    }

    private static func font(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        _ = BrandResources.registeredFonts
        return .custom(name, size: size, relativeTo: style)
    }
}

public struct AppIcon: View {
    private let name: String
    private let size: CGFloat
    public init(_ name: String, size: CGFloat = AppLayout.iconSize) { self.name = name; self.size = size }
    public var body: some View {
        Image("phosphor-\(name)", bundle: .module)
            .resizable().scaledToFit().frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
