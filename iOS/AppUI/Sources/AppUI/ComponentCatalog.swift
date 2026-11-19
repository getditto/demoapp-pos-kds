#if DEBUG
import SwiftUI

public struct ComponentCatalog: View {
    @State private var text = ""
    @State private var selected = true
    public init() {}
    public var body: some View {
        BrandTheme {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AppHeader("Components", location: "Ham's Burgers")
                    HStack(spacing: AppLayout.gap) {
                        Button("Primary") {}.buttonStyle(AppButtonStyle())
                        Button("Disabled") {}.buttonStyle(AppButtonStyle()).disabled(true)
                    }
                    Button("Secondary") {}.buttonStyle(AppButtonStyle(.secondary))
                    Button("Text action") {}.buttonStyle(AppButtonStyle(.text))
                    AppField("Name", error: "Enter a name.") { TextField("Name", text: $text) }
                    AppRow("Ditto Tools") { AppIcon("caret-right") }
                    AppChoiceRow("Selected option", selected: selected) { selected.toggle() }
                    HStack(alignment: .top, spacing: 16) {
                        AppWell { AppEmptyState("No orders preparing", message: "New orders will appear here.", icon: "cooking-pot") }
                        AppSurface { Text("#32B9A42D").font(AppTypography.action); Text("2 × Burger") }
                    }.frame(minHeight: 260)
                    HStack(alignment: .top, spacing: 16) {
                        AppSurface { Text("#32B9A42D").font(AppTypography.action); Text("2 × Burger") }
                        AppWell { AppEmptyState("No orders ready", message: "Completed orders will appear here.", icon: "cooking-pot") }
                    }.frame(minHeight: 260)
                }.padding(AppLayout.padding)
            }
        }
    }
}

#Preview("Components · Light") { ComponentCatalog().environment(\.colorScheme, .light) }
#Preview("Components · Dark") { ComponentCatalog().environment(\.colorScheme, .dark) }
#Preview("Components · Large type") { ComponentCatalog().dynamicTypeSize(.accessibility2) }
#endif
