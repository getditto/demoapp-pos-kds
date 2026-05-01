//
//  DemoSeeder.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// Demo-only orchestration. Seed content is in LocationSeed / SaleItemSeed.

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
        for location in LocationSeed.demoLocations {
            await execute(
                """
                INSERT INTO \(Location.collectionName)
                INITIAL DOCUMENTS (deserialize_json(:json))
                """,
                args: ["json": location.dittoJSONString()],
                label: "seedLocations"
            )
        }
    }

    func seedSaleItems() async {
        for item in SaleItemSeed.saleItemsForAllLocations() {
            await execute(
                """
                INSERT INTO \(SaleItem.collectionName)
                INITIAL DOCUMENTS (deserialize_json(:json))
                """,
                args: ["json": item.dittoJSONString()],
                label: "seedSaleItems"
            )
        }
    }

    private func execute(_ query: String, args: [String: Any?], label: String) async {
        do {
            _ = try await store.execute(query: query, arguments: args)
        } catch {
            print("DemoSeeder.\(label): ERROR \(error.localizedDescription)")
        }
    }
}
