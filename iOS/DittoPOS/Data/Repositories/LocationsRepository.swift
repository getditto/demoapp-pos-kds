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

    private let dittoManager: DittoManager
    private var ditto: Ditto { dittoManager.ditto }
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var locationsObserver = AnyCancellable({})
    private var currentLocationDerivation = AnyCancellable({})

    init(dittoManager: DittoManager = .shared) {
        self.dittoManager = dittoManager
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
        locationsObserver.cancel()
        if visible { observeAllLocations() }
    }

    func setActiveLocation(_ locationId: String?) {
        Settings.locationId = locationId
        currentLocationId = locationId
        if let locationId {
            dittoManager.applySyncGroup(locationId: locationId)
        } else {
            dittoManager.resetSyncGroup()
        }
    }

    private func startSubscription() {
        do {
            subscription = try sync.registerSubscription(
                query: "SELECT * FROM \(Location.collectionName)"
            )
        } catch {
            reportSubscriptionFailure("subscribe locations", error)
        }
    }

    private func observeAllLocations() {
        locationsObserver = store.observePublisher(
            query: "SELECT * FROM \(Location.collectionName)",
            mapTo: Location.self
        )
        .map { locations in
            locations.filter { LocationSeed.demoLocationIds.contains($0.id) }
        }
        .replaceError(with: [])
        .assign(to: \.allLocations, on: self)
    }

    private func deriveCurrentLocation() {
        currentLocationDerivation = Publishers.CombineLatest($currentLocationId, $allLocations)
            .map { id, all in
                guard let id else { return nil }
                return all.first { $0.id == id }
            }
            .assign(to: \.currentLocation, on: self)
    }
}
