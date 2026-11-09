import Combine
import DittoUI
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor final class AppearanceSettings: ObservableObject {
    @Published var selection: AppAppearance {
        didSet { defaults.set(selection.rawValue, forKey: Self.key) }
    }

    private static let key = "live.ditto.DittoPOS.appearance"
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        selection = defaults.string(forKey: Self.key).flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}

struct AppTheme<Content: View>: View {
    @ObservedObject var appearance: AppearanceSettings
    private let content: Content

    init(appearance: AppearanceSettings, @ViewBuilder content: () -> Content) {
        self.appearance = appearance
        self.content = content()
    }

    var body: some View {
        DittoTheme { content }
            .preferredColorScheme(appearance.selection.colorScheme)
    }
}
