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
        do {
            let sub = try sync.registerSubscription(
                query: """
                    SELECT * FROM \(SaleItem.collectionName)
                    WHERE _id.locationId = :locationId
                    ORDER BY name
                    """,
                arguments: ["locationId": locationId]
            )
            subscription = sub

            observer = store.observePublisher(
                query: sub.queryString,
                arguments: sub.queryArguments,
                mapTo: SaleItem.self
            )
            .replaceError(with: [])
            .assign(to: \.locationSaleItems, on: self)
        } catch {
            assertionFailure("subscribe sale_items failed: \(error.localizedDescription)")
        }
    }
}
