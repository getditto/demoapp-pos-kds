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

    nonisolated static let catalogQuery = """
        SELECT * FROM sale_items
        WHERE _id.locationId = :locationId
        ORDER BY name, _id.id
        """

    func observeLocationSaleItems(_ locationId: String) -> AnyPublisher<[SaleItem], Never> {
        store.observePublisher(query: Self.catalogQuery, arguments: ["locationId": locationId], mapTo: SaleItem.self)
            .map { [store] items -> AnyPublisher<[SaleItem], Never> in
                guard SeedStockMigration.mayNeedUpgrade(items) else { return Just(items).eraseToAnyPublisher() }
                return Deferred {
                    CatalogPreparation(store: store, locationId: locationId).publisher
                }.eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func create(_ payload: SaleItemCreation) async throws { try await SaleItemCommands.create(payload, store: store) }
    func updateMetadata(_ metadata: SaleItemMetadata) async throws { try await SaleItemCommands.updateMetadata(metadata, store: store) }
    func increment(_ delta: Int64, id: DocumentID) async throws { try await SaleItemCommands.increment(delta, id: id, store: store) }
    func restart(_ quantity: Int64, id: DocumentID) async throws { try await SaleItemCommands.restart(quantity, id: id, store: store) }
}

// Preparing legacy stock must finish before this query result becomes ready for the UI.
@MainActor private final class CatalogPreparation {
    private let result = CurrentValueSubject<[SaleItem]?, Never>(nil)
    private var task: Task<Void, Never>?

    init(store: DittoStore, locationId: String) {
        task = Task {
            do {
                let items: [SaleItem] = try await store.transaction { transaction in
                    try await SeedStockMigration.upgrade(locationId: locationId, transaction: transaction)
                    let current = try await transaction.execute(
                        query: SaleItemsRepository.catalogQuery, arguments: ["locationId": locationId])
                    return current.decodeOrSkip()
                }
                guard !Task.isCancelled else { return }
                result.send(items)
                result.send(completion: .finished)
            } catch {
                guard !Task.isCancelled else { return }
                preconditionFailure("Catalog preparation failed: \(error)")
            }
        }
    }

    var publisher: AnyPublisher<[SaleItem], Never> {
        result.compactMap { $0 }
            .handleEvents(receiveCancel: { self.task?.cancel() })
            .eraseToAnyPublisher()
    }
}
