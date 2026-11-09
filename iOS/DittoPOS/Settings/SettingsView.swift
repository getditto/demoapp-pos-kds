import DittoAllToolsMenu
import DittoSwift
import DittoUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appearance: AppearanceSettings
    @EnvironmentObject private var locationsRepository: LocationsRepository
    @State private var showsLocations = false
    @State private var showsTools = false
    let onSelectLocation: (String) -> Void

    var body: some View {
        SettingsContent(location: locationsRepository.currentLocation?.name ?? "Location",
                        appearance: $appearance.selection,
                        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                        build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
                        sdkVersion: Ditto.version,
                        onLocation: { showsLocations = true }, onTools: { showsTools = true })
            .navigationDestination(isPresented: $showsLocations) {
                LocationsView(locationsRepository: locationsRepository, onSelect: onSelectLocation)
            }
            .navigationDestination(isPresented: $showsTools) {
                AllToolsMenu(ditto: DittoManager.shared.ditto)
                    .toolbar(.visible, for: .navigationBar)
                    .navigationTitle("Ditto Tools")
            }
    }
}
