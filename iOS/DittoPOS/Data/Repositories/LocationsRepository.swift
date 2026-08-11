//
//  LocationsRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

/// Owns the `locations` collection and the in-memory state for the currently
/// selected location. `allLocations` is filtered to the seven demo location
/// IDs defensively. `currentLocationId` is the single source of truth for
/// "which location is active" — UI calls `setActive(_:)` to switch and the
/// per-collection repositories react via their own subscriptions to
/// `$currentLocationId`. `currentLocation` is a convenience derivation for
/// views.
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
        observeAllLocations()
        deriveCurrentLocation()
        // Restore the persisted active location on launch — but only if it's
        // still one of the seven demo locations. Passes through the same setter
        // the UI uses, so the sync group is applied here too.
        if let saved = Settings.locationId {
            if LocationSeed.demoLocationIds.contains(saved) {
                setActiveLocation(saved)
            } else {
                // Stale id (e.g. a legacy custom location that no longer
                // exists). Clear it so the user is forced to re-pick, and reset
                // the sync group to default.
                setActiveLocation(nil)
            }
        }
    }

    /// Switch the active location. Persists, publishes, and applies Ditto's
    /// sync group. Pass `nil` to clear the selection and reset the sync group
    /// back to default.
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
