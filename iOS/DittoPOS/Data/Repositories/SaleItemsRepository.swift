//
//  SaleItemsRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

@MainActor final class SaleItemsRepository: ObservableObject {

    private let ditto: Ditto
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var locationSubscription = AnyCancellable({})

    init(ditto: Ditto, locationPublisher: AnyPublisher<String?, Never>) {
        self.ditto = ditto
        locationSubscription = locationPublisher
            .removeDuplicates()
            .sink { [weak self] locationId in
                self?.setActiveLocation(locationId)
            }
    }

    private func setActiveLocation(_ locationId: String?) {
        subscription?.cancel()
        subscription = nil
        guard let locationId else { return }

        // Sync stays active across tabs; local query lifetimes belong to the visible UI.
        // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
        subscription = try! sync.registerSubscription(
            query: """
                SELECT * FROM \(SaleItem.collectionName)
                WHERE _id.locationId = :locationId
                """,
            arguments: ["locationId": locationId]
        )
    }

    func observeLocationSaleItems(_ locationId: String) -> AnyPublisher<[SaleItem], Never> {
        store.observePublisher(
            query: """
                SELECT * FROM \(SaleItem.collectionName)
                WHERE _id.locationId = :locationId
                ORDER BY name, _id.id
                """,
            arguments: ["locationId": locationId],
            mapTo: SaleItem.self
        )
    }

    func create(_ payload: SaleItemCreation) async throws { try await SaleItemCommands.create(payload, store: store) }
    func updateMetadata(_ metadata: SaleItemMetadata) async throws { try await SaleItemCommands.updateMetadata(metadata, store: store) }
    func increment(_ delta: Int64, id: DocumentID) async throws { try await SaleItemCommands.increment(delta, id: id, store: store) }
    func restart(_ quantity: Int64, id: DocumentID) async throws { try await SaleItemCommands.restart(quantity, id: id, store: store) }
}
