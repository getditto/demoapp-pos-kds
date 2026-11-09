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
            Text("Inventory").font(.custom("ChakraPetch-Regular", size: 34, relativeTo: .largeTitle))
            Text("Geist · Regular 400").font(.caption)
            Text("Burger, coffee and café au lait.\nÀé ñ · $0.00 · $19.95")
                .font(.custom("Geist-Regular", size: 17, relativeTo: .body))
            Text("Geist Mono · Regular 400").font(.caption)
            Text("NEW ITEM   0123456789   + −")
                .font(.custom("GeistMono-Regular", size: 15, relativeTo: .callout))
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
