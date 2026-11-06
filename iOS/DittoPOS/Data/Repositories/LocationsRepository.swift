//
//  LocationsRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

// Location selection is device-local so it cannot switch another demo device.
@MainActor final class LocationsRepository: ObservableObject {

    @Published private(set) var allLocations: [Location] = []
    @Published private(set) var currentLocationId: String?
    @Published private(set) var currentLocation: Location?
    @Published private(set) var isLoading = true

    private let ditto: Ditto
    private let updateSyncGroup: (String?) -> Void
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var locationsObserver = AnyCancellable({})
    private var isVisible = false

    init(ditto: Ditto, updateSyncGroup: @escaping (String?) -> Void) {
        self.ditto = ditto
        self.updateSyncGroup = updateSyncGroup
        startSubscription()
        deriveCurrentLocation()
        if let saved = Settings.locationId {
            if LocationSeed.demoLocationIds.contains(saved) {
                setActiveLocation(saved)
            } else {
                // Retired custom-location IDs must not bypass setup.
                setActiveLocation(nil)
            }
        }
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        locationsObserver.cancel()
        allLocations = []
        isLoading = true
        if visible { observeAllLocations() }
    }

    func setActiveLocation(_ locationId: String?) {
        Settings.locationId = locationId
        currentLocationId = locationId
        updateSyncGroup(locationId)
    }

    private func startSubscription() {
        subscription = try! sync.registerSubscription(query: "SELECT * FROM \(Location.collectionName)")
    }

    private func observeAllLocations() {
        locationsObserver = store.observePublisher(
            query: "SELECT * FROM \(Location.collectionName)",
            mapTo: Location.self
        )
        .map { locations in
            locations.filter { LocationSeed.demoLocationIds.contains($0.id) }
        }
        .sink { [weak self] locations in
            self?.allLocations = locations
            self?.isLoading = false
        }
    }

    private func deriveCurrentLocation() {
        Publishers.CombineLatest($currentLocationId, $allLocations)
            .map { id, all in
                guard let id else { return nil }
                return all.first { $0.id == id }
            }
            .assign(to: &$currentLocation)
    }
}
