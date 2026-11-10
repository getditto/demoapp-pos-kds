import SwiftUI

public struct DittoPhoto: View {
    private let image: Image?
    private let contentMode: ContentMode
    private let cornerRadius: CGFloat
    private let iconSize: CGFloat

    public init(image: Image?, contentMode: ContentMode = .fit, cornerRadius: CGFloat = 8, iconSize: CGFloat = 24) {
        self.image = image
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.iconSize = iconSize
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                DittoColors.surface
                if let image {
                    image.resizable().aspectRatio(contentMode: contentMode)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    DittoIcon("image", size: iconSize).foregroundStyle(DittoColors.secondaryText)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }
}
