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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: sizeClass == .regular ? 16 : 12) {
                        Button(action: onLocation) {
                            AppRow(location, eyebrow: "Location") { AppIcon("caret-right") }
                        }.buttonStyle(.plain)
                        AppSurface {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Appearance").font(AppTypography.body.weight(.medium))
                                Text("System follows this device’s setting.")
                                    .font(AppTypography.footnote).foregroundStyle(AppColors.secondaryText)
                                ForEach(AppAppearance.allCases) { option in
                                    AppChoiceRow(option.rawValue.capitalized, selected: appearance == option) { appearance = option }
                                }
                            }
                        }
                        Button(action: onTools) {
                            AppRow("Ditto Tools") { AppIcon("caret-right") }
                        }.buttonStyle(.plain)
                    }
                    Spacer(minLength: 24)
                    VStack(spacing: 4) {
                        Text("Build \(version) (\(build))")
                        Text("Powered by Ditto Edge SDK \(sdkVersion)")
                        Link("ditto.com", destination: URL(string: "https://ditto.com")!)
                            .underline().frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }
                .frame(minHeight: max(0, geometry.size.height - 32), alignment: .top)
                .padding(.horizontal, sizeClass == .regular ? 20 : AppLayout.padding)
                .padding(.vertical, AppLayout.padding)
            }
        }
        .background(AppColors.background)
    }
}

#Preview("Settings") {
    BrandTheme {
        VStack(spacing: 0) {
            AppHeader("Settings", location: "Ham's Burgers")
            SettingsContent(location: "Ham's Burgers", appearance: .constant(.system), version: "1.1.0", build: "9999", sdkVersion: "5.2.0", onLocation: {}, onTools: {})
        }
    }
}
