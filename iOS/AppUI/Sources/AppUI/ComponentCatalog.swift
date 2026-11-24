#if DEBUG
import SwiftUI

public struct ComponentCatalog: View {
    @State private var text = ""
    @State private var selected = true
    public init() {}
    public var body: some View {
        BrandTheme {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.sectionGap) {
                    AppHeader("Components") { Text("Context").font(AppTypography.footnote) }
                    HStack(spacing: AppLayout.gap) {
                        Button("Primary") {}.buttonStyle(AppButtonStyle())
                        Button("Disabled") {}.buttonStyle(AppButtonStyle()).disabled(true)
                    }
                    Button("Secondary") {}.buttonStyle(AppButtonStyle(.secondary))
                    Button("Text action") {}.buttonStyle(AppButtonStyle(.text))
                    AppField("Name", error: "Enter a name.") { TextField("Name", text: $text) }
                    AppRow("Navigation row") { AppIcon("caret-right") }
                    AppChoiceRow("Selected option", selected: selected) { selected.toggle() }
                    AppSurface { Text("Surface content").font(AppTypography.body) }
                    AppSurface(style: .outlined) { Text("Outlined surface").font(AppTypography.body) }
                    AppSurface(style: .compact) { Text("Compact surface").font(AppTypography.body) }
                    AppWell { Text("Empty region").foregroundStyle(AppColors.secondaryText) }
                    AppPhoto(image: nil).frame(width: AppLayout.thumbnailSize, height: AppLayout.thumbnailSize)
                }.padding(AppLayout.padding)
            }
        }
    }
}

#Preview("Components · Light") { ComponentCatalog().environment(\.colorScheme, .light) }
#Preview("Components · Dark") { ComponentCatalog().environment(\.colorScheme, .dark) }
#Preview("Components · Large type") { ComponentCatalog().dynamicTypeSize(.accessibility2) }
#endif
