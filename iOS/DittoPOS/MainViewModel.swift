//
//  MainViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import Foundation

/// Owns the root-view state: whether a location still needs picking, which tab
/// is selected, whether the settings sheet is presented, and the title shown in
/// the nav bar. Subscribes to `LocationsRepository` so picking a location opens
/// the app on the POS tab and the title follows the active location. Mirrors
/// Android's `MainViewModel`.
@MainActor final class MainViewModel: ObservableObject {

    /// Gates the whole app. POS and KDS are meaningless without a location —
    /// they render an empty menu and no order — so the picker blocks until one
    /// is chosen. Mirrors Android's `AppConfigurationState.LOCATION_NEEDED`.
    @Published private(set) var needsLocation: Bool
    @Published var selectedTab: TabViews
    @Published var presentSettingsView = false
    @Published private(set) var mainTitle = "Please Select Location"

    private let locationsRepository: LocationsRepository
    private var cancellables = Set<AnyCancellable>()

    init(locationsRepository: LocationsRepository) {
        self.locationsRepository = locationsRepository
        needsLocation = locationsRepository.currentLocationId == nil
        selectedTab = Settings.selectedTabView ?? .pos

        // Persist tab selection.
        $selectedTab
            .dropFirst()
            .sink { Settings.selectedTabView = $0 }
            .store(in: &cancellables)

        // Open on POS once a location becomes active.
        locationsRepository.$currentLocationId
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] _ in self?.selectedTab = .pos }
            .store(in: &cancellables)

        // Clearing the location puts the picker back up.
        locationsRepository.$currentLocationId
            .map { $0 == nil }
            .assign(to: &$needsLocation)

        // Title follows the active location.
        locationsRepository.$currentLocation
            .map { $0?.name ?? "Please Select Location" }
            .assign(to: &$mainTitle)
    }
}
