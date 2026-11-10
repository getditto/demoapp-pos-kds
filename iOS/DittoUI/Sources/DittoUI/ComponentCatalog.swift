#if DEBUG
import SwiftUI

public struct DittoComponentCatalog: View {
    @State private var text = ""
    @State private var selected = true
    public init() {}
    public var body: some View {
        DittoTheme {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DittoHeader("Components", location: "Ham's Burgers")
                    HStack(spacing: DittoLayout.gap) {
                        Button("Primary") {}.buttonStyle(DittoButtonStyle())
                        Button("Disabled") {}.buttonStyle(DittoButtonStyle()).disabled(true)
                    }
                    Button("Secondary") {}.buttonStyle(DittoButtonStyle(.secondary))
                    Button("Text action") {}.buttonStyle(DittoButtonStyle(.text))
                    DittoField("Name", error: "Enter a name.") { TextField("Name", text: $text) }
                    DittoRow("Ditto Tools") { DittoIcon("caret-right") }
                    DittoChoiceRow("Selected option", selected: selected) { selected.toggle() }
                    HStack(alignment: .top, spacing: 16) {
                        DittoWell { DittoEmptyState("No orders preparing", message: "New orders will appear here.", icon: "cooking-pot") }
                        DittoSurface { Text("#32B9A42D").font(DittoTypography.action); Text("2 × Burger") }
                    }.frame(minHeight: 260)
                    HStack(alignment: .top, spacing: 16) {
                        DittoSurface { Text("#32B9A42D").font(DittoTypography.action); Text("2 × Burger") }
                        DittoWell { DittoEmptyState("No orders ready", message: "Completed orders will appear here.", icon: "cooking-pot") }
                    }.frame(minHeight: 260)
                }.padding(DittoLayout.padding)
            }
        }
    }
}

#Preview("Components · Light") { DittoComponentCatalog().environment(\.colorScheme, .light) }
#Preview("Components · Dark") { DittoComponentCatalog().environment(\.colorScheme, .dark) }
#Preview("Components · Large type") { DittoComponentCatalog().dynamicTypeSize(.accessibility2) }
#endif
