//
//  MainViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import Foundation

/// Owns the root-view state: which tab is selected, whether the settings
/// sheet is presented, and the title shown in the nav bar. Subscribes to
/// `LocationsRepository` so picking a location auto-switches to the POS tab
/// and the title follows the active location. Mirrors Android's
/// `MainViewModel`.
@MainActor final class MainViewModel: ObservableObject {

    @Published var selectedTab: TabViews
    @Published var presentSettingsView = false
    @Published private(set) var mainTitle = "Please Select Location"

    private let locationsRepository: LocationsRepository
    private var cancellables = Set<AnyCancellable>()

    init(locationsRepository: LocationsRepository) {
        self.locationsRepository = locationsRepository
        selectedTab = locationsRepository.currentLocationId == nil
            ? .locations
            : (Settings.selectedTabView ?? .pos)

        // Persist tab selection.
        $selectedTab
            .dropFirst()
            .sink { Settings.selectedTabView = $0 }
            .store(in: &cancellables)

        // Auto-switch to POS once a location becomes active.
        locationsRepository.$currentLocationId
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] _ in self?.selectedTab = .pos }
            .store(in: &cancellables)

        // Title follows the active location.
        locationsRepository.$currentLocation
            .map { $0?.name ?? "Please Select Location" }
            .assign(to: &$mainTitle)
    }

    /// Called from `MainView.onAppear`. If no location is active, make sure
    /// we're on the Locations tab so the user is prompted to pick one.
    func ensureLocationSelected() {
        if locationsRepository.currentLocationId == nil {
            selectedTab = .locations
        }
    }
}
