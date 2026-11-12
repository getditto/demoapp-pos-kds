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
                    HStack(alignment: .top, spacing: 24) {
                        DittoWell { Text("No orders preparing").foregroundStyle(DittoColors.secondaryText) }
                        DittoTicket(title: "#32B9A42D", lines: ["2 × Burger"], isPaid: true, elapsed: "2 min ago", isReady: true) {}
                    }
                    HStack(alignment: .top, spacing: 24) {
                        DittoTicket(title: "#32B9A42D", lines: ["2 × Burger"], isPaid: false, elapsed: "2 min ago", isReady: false) {}
                        DittoWell { Text("No orders ready").foregroundStyle(DittoColors.secondaryText) }
                    }
                }.padding(DittoLayout.padding)
            }
        }
    }
}

#Preview("Components · Light") { DittoComponentCatalog().environment(\.colorScheme, .light) }
#Preview("Components · Dark") { DittoComponentCatalog().environment(\.colorScheme, .dark) }
#Preview("Components · Large type") { DittoComponentCatalog().dynamicTypeSize(.accessibility2) }
#endif
