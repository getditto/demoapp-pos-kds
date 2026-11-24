import Foundation

public struct AppQuantityFieldViewModel {
    public static let digitWidth: CGFloat = 11
    private static let maximumWidth: CGFloat = 144
    public let width: CGFloat

    public init(text: String, scaledDigitWidth: CGFloat) {
        width = min(Self.maximumWidth, max(AppLayout.controlHeight, CGFloat(text.count) * scaledDigitWidth + AppLayout.padding))
    }
}
