//
//  MainViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import Foundation

@MainActor final class MainViewModel: ObservableObject {

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

        $selectedTab
            .dropFirst()
            .sink { Settings.selectedTabView = $0 }
            .store(in: &cancellables)

        locationsRepository.$currentLocationId
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] _ in self?.selectedTab = .pos }
            .store(in: &cancellables)

        locationsRepository.$currentLocationId
            .map { $0 == nil }
            .assign(to: &$needsLocation)

        Publishers.CombineLatest(locationsRepository.$currentLocationId, locationsRepository.$currentLocation)
            .map { id, location in location?.name ?? (id == nil ? "Please Select Location" : "Location") }
            .assign(to: &$mainTitle)
    }
}
