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
                    HStack(alignment: .top, spacing: 24) {
                        AppWell { Text("No orders preparing").foregroundStyle(AppColors.secondaryText) }
                        AppTicket(title: "#32B9A42D", lines: ["2 × Burger"], isPaid: true, elapsed: "2 min ago", isReady: true) {}
                    }
                    HStack(alignment: .top, spacing: 24) {
                        AppTicket(title: "#32B9A42D", lines: ["2 × Burger"], isPaid: false, elapsed: "2 min ago", isReady: false) {}
                        AppWell { Text("No orders ready").foregroundStyle(AppColors.secondaryText) }
                    }
                }.padding(AppLayout.padding)
            }
        }
    }
}

#Preview("Components · Light") { ComponentCatalog().environment(\.colorScheme, .light) }
#Preview("Components · Dark") { ComponentCatalog().environment(\.colorScheme, .dark) }
#Preview("Components · Large type") { ComponentCatalog().dynamicTypeSize(.accessibility2) }
#endif
