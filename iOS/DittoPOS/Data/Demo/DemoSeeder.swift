//
//  DemoSeeder.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// Demo-only orchestration. Seed content is in LocationSeed / SaleItemSeed.
//
// `INITIAL DOCUMENTS` writes each document only if it doesn't already exist
// — idempotent and peer-safe, so every device can run this on launch and
// the network converges on a single copy.

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
            documents: LocationSeed.demoLocations,
            label: "seedLocations"
        )
    }

    func seedSaleItems() async {
        await bulkInitialInsert(
            into: SaleItem.collectionName,
            documents: SaleItemSeed.saleItemsForAllLocations(),
            label: "seedSaleItems"
        )
    }

    /// Single bulk `INSERT INTO ... INITIAL DOCUMENTS (...), (...), ...`
    /// — one round-trip for the whole seed set.
    private func bulkInitialInsert<T: Encodable>(
        into collectionName: String,
        documents: [T],
        label: String
    ) async {
        guard !documents.isEmpty else { return }

        var args: [String: Any?] = [:]
        var placeholders: [String] = []
        for (index, document) in documents.enumerated() {
            let key = "d\(index)"
            args[key] = (try? document.dittoJSONString()) ?? "{}"
            placeholders.append("(deserialize_json(:\(key)))")
        }

        do {
            _ = try await store.execute(
                query: """
                    INSERT INTO \(collectionName)
                    INITIAL DOCUMENTS \(placeholders.joined(separator: ", "))
                    """,
                arguments: args
            )
        } catch {
            print("DemoSeeder.\(label): ERROR \(error.localizedDescription)")
        }
    }
}
