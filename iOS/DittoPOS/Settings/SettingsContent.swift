import DittoUI
import SwiftUI

struct SettingsContent: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let location: String
    @Binding var appearance: AppAppearance
    let version: String
    let build: String
    let sdkVersion: String
    let onLocation: () -> Void
    let onTools: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button(action: onLocation) {
                    DittoRow("Location", detail: location, icon: "map-pin") { DittoIcon("caret-right") }
                }.buttonStyle(.plain)
                DittoSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance").font(DittoTypography.heading)
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag(AppAppearance.system)
                            Text("Light").tag(AppAppearance.light)
                            Text("Dark").tag(AppAppearance.dark)
                        }.pickerStyle(.segmented)
                    }
                }
                Button(action: onTools) {
                    DittoRow("Ditto Tools", icon: "gear") { DittoIcon("caret-right") }
                }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Build \(version) (\(build))")
                    Text("Powered by Ditto Edge SDK \(sdkVersion)")
                    Link("ditto.com", destination: URL(string: "https://ditto.com")!)
                        .underline()
                }.font(DittoTypography.caption).foregroundStyle(DittoColors.secondaryText)
            }
            .padding(.horizontal, sizeClass == .regular ? 20 : DittoLayout.padding)
            .padding(.vertical, DittoLayout.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DittoColors.background)
    }
}

#Preview("Settings") {
    DittoTheme {
        VStack(spacing: 0) {
            DittoHeader("Settings", location: "Ham's Burgers")
            SettingsContent(location: "Ham's Burgers", appearance: .constant(.system), version: "1.1.0", build: "9999", sdkVersion: "5.2.0", onLocation: {}, onTools: {})
        }
    }
}
