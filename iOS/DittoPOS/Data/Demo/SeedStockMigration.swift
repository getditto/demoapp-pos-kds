import DittoSwift

// INITIAL seeds leave existing documents unchanged, so legacy stock needs its own guarded update.
// https://docs.ditto.live/dql/types-and-definitions#creating-counters
enum SeedStockMigration {
    private static let seedIDs = Set(SaleItemSeed.saleItemsForAllLocations().map(\.documentId))

    static func mayNeedUpgrade(_ items: [SaleItem]) -> Bool {
        items.contains { $0.quantity == nil && seedIDs.contains($0.documentId) }
    }

    static func upgrade(locationId: String, transaction: DittoTransaction) async throws {
        let result = try await transaction.execute(
            query: "SELECT * FROM sale_items WHERE _id.locationId = :locationId AND quantity IS MISSING",
            arguments: ["locationId": locationId])
        let items: [SaleItem] = result.decodeOrSkip()
        for item in items where seedIDs.contains(item.documentId) {
            _ = try await transaction.execute(
                query: """
                    UPDATE sale_items APPLY quantity RESTART WITH :initialQuantity
                    WHERE _id.id = :id AND _id.locationId = :locationId AND quantity IS MISSING
                    """,
                arguments: ["id": item.documentId.id, "locationId": locationId, "initialQuantity": SaleItemSeed.initialQuantity])
        }
    }

    static func upgradeAll(store: DittoStore) async throws {
        _ = try await store.transaction { transaction in
            for location in LocationSeed.demoLocations {
                try await upgrade(locationId: location.id, transaction: transaction)
            }
            return DittoTransactionCompletionAction.commit
        }
    }
}
