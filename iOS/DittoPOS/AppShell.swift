import AppUI
import SwiftUI

struct AppShell<POS: View, KDS: View, SettingsPage: View, Locations: View>: View {
    @Binding var selectedTab: TabViews
    let needsLocation: Bool
    let location: String?
    private let pos: POS
    private let kds: KDS
    private let settings: SettingsPage
    private let locations: Locations

    init(selectedTab: Binding<TabViews>, needsLocation: Bool, location: String?,
         @ViewBuilder pos: () -> POS, @ViewBuilder kds: () -> KDS,
         @ViewBuilder settings: () -> SettingsPage, @ViewBuilder locations: () -> Locations) {
        _selectedTab = selectedTab
        self.needsLocation = needsLocation
        self.location = location
        self.pos = pos(); self.kds = kds(); self.settings = settings(); self.locations = locations()
    }

    var body: some View {
        NavigationStack {
            Group {
                if needsLocation {
                    locations
                } else {
                    VStack(spacing: 0) {
                        LocationHeader(title: title, location: location)
                        TabView(selection: $selectedTab) {
                            pos.tabItem { Label { Text("POS") } icon: { AppIcon("cash-register") } }.tag(TabViews.pos)
                            kds.tabItem { Label { Text("KDS") } icon: { AppIcon("cooking-pot") } }.tag(TabViews.kds)
                            settings.tabItem { Label { Text("Settings") } icon: { AppIcon("gear") } }.tag(TabViews.settings)
                        }
                        .toolbarBackground(AppColors.surface, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var title: String {
        switch selectedTab {
        case .pos: return "POS"
        case .kds: return "Kitchen display"
        case .settings: return "Settings"
        }
    }
}

struct LocationHeader: View {
    let title: String
    let location: String?
    var body: some View {
        AppHeader(title) {
            if let location, !location.isEmpty {
                HStack(spacing: AppLayout.accessoryGap) {
                    AppIcon("map-pin", size: AppLayout.secondaryIconSize)
                    Text(location).font(AppTypography.footnote)
                }.foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}
