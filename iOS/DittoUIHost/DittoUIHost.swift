import DittoUI
import SwiftUI

// This host exercises the real presentation layer without the demo or its database.
@main
struct DittoUIHost: App {
    @StateObject private var appearance: AppearanceSettings

    init() {
        let suite = ProcessInfo.processInfo.environment["UI_TEST_SETTINGS_SUITE"] ?? "DittoUIHost"
        let defaults = UserDefaults(suiteName: suite)!
        if ProcessInfo.processInfo.arguments.contains("--reset-settings") { defaults.removePersistentDomain(forName: suite) }
        _appearance = StateObject(wrappedValue: AppearanceSettings(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            AppTheme(appearance: appearance) {
                PresentationFixture(appearance: appearance)
            }
        }
    }
}

private struct PresentationFixture: View {
    @ObservedObject var appearance: AppearanceSettings
    @Environment(\.colorScheme) private var scheme
    @State private var selectedTab = TabViews.pos

    var body: some View {
        AppShell(selectedTab: $selectedTab, needsLocation: false, location: "Ham's Burgers") {
            DraftPage()
        } kds: {
            DittoEmptyState("No active orders", message: "Orders entered in POS will appear here.", icon: "cooking-pot")
        } settings: {
            SettingsContent(location: "Ham's Burgers", appearance: $appearance.selection,
                            version: "1.1.0", build: "9999", sdkVersion: "5.2.0", onLocation: {}, onTools: {})
        } locations: {
            EmptyView()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app-shell")
        .accessibilityValue(scheme == .dark ? "Dark" : "Light")
    }
}

private struct DraftPage: View {
    @State private var draft = ""
    @FocusState private var focused: Bool
    var body: some View {
        TextField("Draft", text: $draft).textFieldStyle(.roundedBorder).padding()
            .focused($focused).submitLabel(.done).onSubmit { focused = false }
    }
}
