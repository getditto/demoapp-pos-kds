//
//  LocationsViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine

@MainActor final class LocationsViewModel: ObservableObject {

    @Published private(set) var locations: [Location] = []
    @Published private(set) var selectedLocation: Location?
    @Published private(set) var isLoading = true

    private let locationsRepository: LocationsRepository
    private var cancellables = Set<AnyCancellable>()

    init(locationsRepository: LocationsRepository) {
        self.locationsRepository = locationsRepository

        locationsRepository.$allLocations.assign(to: &$locations)
        locationsRepository.$isLoading.assign(to: &$isLoading)

        Publishers.CombineLatest(
            locationsRepository.$allLocations,
            locationsRepository.$currentLocationId
        )
        .map { all, id in
            guard let id else { return nil as Location? }
            return all.first { $0.id == id }
        }
        .assign(to: &$selectedLocation)
    }

}
