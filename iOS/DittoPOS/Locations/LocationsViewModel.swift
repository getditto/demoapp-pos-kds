//
//  LocationsViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import SwiftUI

/// Wraps `LocationsRepository` for the Locations tab: exposes the list of
/// locations and the currently selected one as `@Published`, plus a
/// `Binding<Location?>` the SwiftUI `List` can drive directly. The
/// "only fire when the id actually changes" guard lives here, not in the
/// view.
@MainActor final class LocationsViewModel: ObservableObject {

    @Published private(set) var locations: [Location] = []
    @Published private(set) var selectedLocation: Location?

    private let locationsRepository: LocationsRepository
    private var cancellables = Set<AnyCancellable>()

    init(locationsRepository: LocationsRepository) {
        self.locationsRepository = locationsRepository

        locationsRepository.$allLocations.assign(to: &$locations)

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

    /// Setter that drops no-op selections (the SwiftUI `List` will write the
    /// current value back on every render).
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
