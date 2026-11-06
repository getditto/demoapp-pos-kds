//
//  LocationsViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import SwiftUI

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

    func selectLocation(_ location: Location?) {
        guard let id = location?.id, id != locationsRepository.currentLocationId else { return }
        locationsRepository.setActiveLocation(id)
    }

    var selectionBinding: Binding<Location?> {
        Binding(
            get: { [weak self] in self?.selectedLocation },
            set: { [weak self] in self?.selectLocation($0) }
        )
    }
}
