//
//  DemoSeeder.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// INITIAL lets peers seed the same defaults without overwriting existing edits.
// https://docs.ditto.live/dql/insert#insert-with-initial-documents

import DittoSwift
import Foundation

@MainActor
struct DemoSeeder {
    let store: DittoStore

    func seedAll() async {
        await seedLocations()
        await seedSaleItems()
    }

    func seedLocations() async {
        await bulkInitialInsert(
            into: Location.collectionName,
            documents: LocationSeed.demoLocations
        )
    }

    func seedSaleItems() async {
        await bulkInitialInsert(
            into: SaleItem.collectionName,
            documents: SaleItemSeed.initialDocuments()
        )
        try! await SeedStockMigration.upgradeAll(store: store)
        try! await SeedImageMigration.upgradeAll(store: store)
    }

    private func bulkInitialInsert<T: Encodable>(
        into collectionName: String,
        documents: [T]
    ) async {
        guard !documents.isEmpty else { return }

        var args: [String: Any?] = [:]
        var placeholders: [String] = []
        for (index, document) in documents.enumerated() {
            let key = "d\(index)"
            args[key] = try! document.dittoJSONString()
            placeholders.append("(deserialize_json(:\(key)))")
        }

        _ = try! await store.execute(
            query: """
                INSERT INTO \(collectionName)
                INITIAL DOCUMENTS \(placeholders.joined(separator: ", "))
                """,
            arguments: args
        )
    }
}
