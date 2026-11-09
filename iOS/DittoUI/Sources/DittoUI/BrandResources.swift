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

public enum DittoTypography {
    public static var pageTitle: Font { font("ChakraPetch-Regular", size: 34, relativeTo: .largeTitle) }
    public static var body: Font { font("Geist-Regular", size: 17, relativeTo: .body) }
    public static var heading: Font { font("Geist-Regular", size: 20, relativeTo: .title3) }
    public static var caption: Font { font("Geist-Regular", size: 14, relativeTo: .subheadline) }
    public static var action: Font { font("GeistMono-Regular", size: 14, relativeTo: .callout) }

    private static func font(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        _ = BrandResources.registeredFonts
        return .custom(name, size: size, relativeTo: style)
    }
}

public struct DittoIcon: View {
    private let name: String
    private let size: CGFloat
    public init(_ name: String, size: CGFloat = 24) { self.name = name; self.size = size }
    public var body: some View {
        Image("phosphor-\(name)", bundle: .module)
            .resizable().scaledToFit().frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
