import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var ordersRepository: OrdersRepository
    @EnvironmentObject var saleItemsRepository: SaleItemsRepository
    @EnvironmentObject var locationsRepository: LocationsRepository
    @StateObject private var viewModel: MainViewModel

    init(locationsRepository: LocationsRepository) {
        _viewModel = StateObject(wrappedValue: MainViewModel(locationsRepository: locationsRepository))
    }

    var body: some View {
        AppShell(selectedTab: $viewModel.selectedTab, needsLocation: viewModel.needsLocation,
                 location: locationsRepository.currentLocation?.name) {
            POSView(ordersRepository: ordersRepository, saleItemsRepository: saleItemsRepository,
                    locationsRepository: locationsRepository,
                    isActive: scenePhase == .active && viewModel.selectedTab == .pos)
        } kds: {
            KDSView(ordersRepository: ordersRepository,
                    isActive: scenePhase == .active && viewModel.selectedTab == .kds)
        } settings: {
            SettingsView(onSelectLocation: viewModel.selectLocation)
        } locations: {
            LocationsView(locationsRepository: locationsRepository, onSelect: viewModel.selectLocation)
        }
        .onAppear { locationsRepository.setVisible(scenePhase == .active) }
        .onChange(of: scenePhase) { locationsRepository.setVisible($0 == .active) }
        .onDisappear { locationsRepository.setVisible(false) }
    }
}
