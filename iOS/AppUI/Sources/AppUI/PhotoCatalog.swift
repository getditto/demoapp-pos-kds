#if DEBUG
import SwiftUI

public struct DittoPhotoCatalog: View {
    private let image: Image?
    private let tablet: Bool

    public init(image: Image? = nil, tablet: Bool = false) {
        self.image = image
        self.tablet = tablet
    }

    public var body: some View {
        DittoTheme {
            VStack(alignment: .leading, spacing: 24) {
                Text("Photos").font(DittoTypography.pageTitle)
                Text("Component preview").font(DittoTypography.footnote).foregroundStyle(DittoColors.secondaryText)
                HStack(spacing: DittoLayout.padding) {
                    thumbnail(image: image, title: image.map { _ in "With photo" } ?? "Photo slot")
                    thumbnail(image: nil, title: "Placeholder")
                }
                HStack(alignment: .top, spacing: DittoLayout.padding) {
                    card(image: image, title: image.map { _ in "With photo" } ?? "Photo slot")
                    card(image: nil, title: "Placeholder")
                }
                Text("Both image slots keep their size as files become available.")
                    .font(DittoTypography.footnote).foregroundStyle(DittoColors.secondaryText)
            }.padding(DittoLayout.padding)
        }
    }

    private func thumbnail(image: Image?, title: String) -> some View {
        HStack(spacing: DittoLayout.gap) {
            DittoPhoto(image: image).frame(width: tablet ? 48 : 40, height: tablet ? 48 : 40)
            Text(title).font(DittoTypography.footnote)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(image: Image?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DittoPhoto(image: image, contentMode: .fit, cornerRadius: 0)
                .frame(height: 112)
            Text(title).font(DittoTypography.body).padding(DittoLayout.padding)
        }
        .frame(maxWidth: .infinity)
        .background(DittoColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DittoLayout.radius))
    }
}

#Preview("Photos · Light") { DittoPhotoCatalog().environment(\.colorScheme, .light) }
#Preview("Photos · Dark") { DittoPhotoCatalog().environment(\.colorScheme, .dark) }
#Preview("Photos · Tablet") { DittoPhotoCatalog(tablet: true).frame(width: 720) }
#endif
