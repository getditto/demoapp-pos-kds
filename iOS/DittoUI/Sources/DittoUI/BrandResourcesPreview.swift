#if DEBUG
import SwiftUI

struct BrandResourcesPreview: View {
    private let icons = [
        "cash-register", "cooking-pot", "receipt", "package", "gear", "map-pin",
        "plus", "minus", "dots-three-vertical", "pencil-simple", "trash", "camera",
        "image", "folder-open", "arrow-left", "caret-right", "check", "x",
        "warning", "sun", "moon", "circle-half"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Chakra Petch · Regular 400").font(.caption)
            Text("Inventory").font(DittoTypography.pageTitle)
            Text("Geist · Regular 400").font(.caption)
            Text("Burger, coffee and café au lait.\nÀé ñ · $0.00 · $19.95")
                .font(DittoTypography.body)
            Text("Geist Mono · Regular 400").font(.caption)
            Text("NEW ITEM   0123456789   + −")
                .font(DittoTypography.action)
            Text("Phosphor · Regular").font(.caption)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 16) {
                ForEach(icons, id: \.self) { name in
                    Image("phosphor-\(name)", bundle: BrandResources.bundle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(24)
        .foregroundStyle(.primary)
        .frame(width: 390, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview("Resources · Light") {
    BrandResourcesPreview().environment(\.colorScheme, .light)
}

#Preview("Resources · Dark") {
    BrandResourcesPreview().environment(\.colorScheme, .dark)
}
#endif
