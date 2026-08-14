//
//  SaleItemsRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

/// Owns the `sale_items` collection: registers the per-location subscription
/// and exposes the synced menu items to consumers. Mirrors Android's
/// `SaleItemsRepository`.
@MainActor final class SaleItemsRepository: ObservableObject {

    @Published private(set) var locationSaleItems: [SaleItem] = []

    private let dittoManager: DittoManager
    private var ditto: Ditto { dittoManager.ditto }
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var observer = AnyCancellable({})
    private var locationSubscription = AnyCancellable({})

    init(dittoManager: DittoManager = .shared, locationsRepository: LocationsRepository) {
        self.dittoManager = dittoManager
        locationSubscription = locationsRepository.$currentLocationId
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] locationId in
                self?.setActiveLocation(locationId)
            }
    }

    private func setActiveLocation(_ locationId: String) {
        subscription?.cancel()

        // Subscription = the sync set: every sale item for this location. ORDER BY
        // / LIMIT are illegal on a subscription in v5. A failed registration must
        // NOT skip the observer below — it's a local read over the store,
        // independent of the sync set (matches Android's separation).
        do {
            subscription = try sync.registerSubscription(
                query: """
                    SELECT * FROM \(SaleItem.collectionName)
                    WHERE _id.locationId = :locationId
                    """,
                arguments: ["locationId": locationId]
            )
        } catch {
            reportSubscriptionFailure("subscribe sale_items", error)
        }

        // Observer = the local read that drives the UI, ordered for display.
        // Its own query string, independent of the subscription's success.
        observer = store.observePublisher(
            query: """
                SELECT * FROM \(SaleItem.collectionName)
                WHERE _id.locationId = :locationId
                ORDER BY name
                """,
            arguments: ["locationId": locationId],
            mapTo: SaleItem.self
        )
        .replaceError(with: [])
        .assign(to: \.locationSaleItems, on: self)
    }
}
