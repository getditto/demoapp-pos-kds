import Combine
import DittoSwift
import XCTest

@MainActor final class SeedStockMigrationTests: XCTestCase {
    func testStartupUpgradesLegacyMenusWithoutResettingEditsStockOrUnrelatedItems() async throws {
        try await TestDitto.withInstance { ditto in
            await LegacyDemoSeeder(store: ditto.store).seedAll()
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            var expected = Dictionary(uniqueKeysWithValues: LegacySaleItemSeed.saleItemsForAllLocations().map {
                ($0.documentId, SaleItemMetadata(documentId: $0.documentId, name: $0.name, price: $0.price))
            })
            for location in LocationSeed.demoLocations {
                let id = try XCTUnwrap(LegacySaleItemSeed.saleItemsForAllLocations().first { $0.documentId.locationId == location.id }?.documentId)
                let edited = SaleItemMetadata(documentId: id, name: "Edited \"\(location.id)\"", price: Price(cents: 0))
                try await catalog.updateMetadata(edited)
                expected[id] = edited
            }
            let positive = DocumentID(id: "00001", locationId: "00001")
            let zero = DocumentID(id: "00008", locationId: "00001")
            let negative = DocumentID(id: "00013", locationId: "00001")
            for (id, value): (DocumentID, Int64) in [(positive, 7), (zero, 0), (negative, -2)] {
                if value < 0 {
                    try await catalog.restart(0, id: id)
                    try await catalog.increment(value, id: id)
                } else {
                    try await catalog.restart(value, id: id)
                }
            }
            let deleted = DocumentID(id: "00018", locationId: "00001")
            let partial = DocumentID(id: "00012", locationId: "00001")
            _ = try await ditto.store.execute(query: "DELETE FROM sale_items WHERE _id = :id", arguments: ["id": ["id": deleted.id, "locationId": deleted.locationId]])
            _ = try await ditto.store.execute(query: "UPDATE sale_items UNSET price WHERE _id = :id", arguments: ["id": ["id": partial.id, "locationId": partial.locationId]])
            expected[deleted] = nil
            expected[partial] = nil
            for id in [DocumentID(id: "f23b0e5a-f372-4578-a4f9-efc8323a4bd7", locationId: "00001"), DocumentID(id: "00001", locationId: "00002")] {
                let item = LegacySaleItem.seed(id: id.id, locationId: id.locationId, name: "Custom", imageName: "coffee", cents: 0)
                _ = try await ditto.store.execute(query: "INSERT INTO sale_items DOCUMENTS (deserialize_json(:json))", arguments: ["json": try item.dittoJSONString()])
                expected[id] = SaleItemMetadata(documentId: id, name: item.name, price: item.price)
            }
            await DemoSeeder(store: ditto.store).seedAll()
            let upgraded = try await allItems(ditto)
            XCTAssertEqual(Dictionary(uniqueKeysWithValues: upgraded.map { ($0.documentId, $0.metadata) }), expected)
            let stock: [DocumentID: Int64] = [positive: 7, zero: 0, negative: -2]
            let seedIDs = Set(LegacySaleItemSeed.saleItemsForAllLocations().map(\.documentId))
            for item in upgraded {
                XCTAssertEqual(item.quantity, seedIDs.contains(item.documentId) ? stock[item.documentId] ?? 20 : nil, String(describing: item.documentId))
            }
            let absent = try await ditto.store.execute(query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId AND quantity IS MISSING", arguments: ["id": partial.id, "locationId": partial.locationId])
            XCTAssertEqual(absent.items.count, 1)
            try await catalog.increment(-1, id: positive)
            let beforeRetry = try await allItems(ditto)
            await DemoSeeder(store: ditto.store).seedAll()
            let afterRetry = try await allItems(ditto)
            XCTAssertEqual(Set(afterRetry), Set(beforeRetry))
        }
    }

    func testMigrationUsesTheCallerTransactionAndCanRetryAfterAnInterruptedUpgrade() async throws {
        enum Interrupted: Error { case expected }
        try await TestDitto.withInstance { ditto in
            await LegacyDemoSeeder(store: ditto.store).seedAll()
            let before = try await allItems(ditto)
            do {
                let _: DittoTransactionCompletionAction = try await ditto.store.transaction { transaction in
                    try await SeedStockMigration.upgrade(locationId: "00001", transaction: transaction)
                    throw Interrupted.expected
                }
                XCTFail("Expected interrupted upgrade")
            } catch Interrupted.expected { }
            let afterFailure = try await allItems(ditto)
            XCTAssertEqual(Set(afterFailure), Set(before))
            let id = DocumentID(id: "00001", locationId: "00001")
            try await SaleItemCommands.restart(0, id: id, store: ditto.store)
            try await SeedStockMigration.upgradeAll(store: ditto.store)
            let retried = try await allItems(ditto)
            XCTAssertEqual(retried.count, before.count)
            for item in retried { XCTAssertEqual(item.quantity, item.documentId == id ? 0 : 20) }
        }
    }

    func testVisibleCatalogUpgradesLateLegacyInputAndLocationReentryPreservesStock() async throws {
        try await TestDitto.withInstance { ditto in
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let latestResult = CurrentValueSubject<[SaleItem]?, Never>(nil)
            var receivedResults: [[SaleItem]] = []
            @MainActor func observe(_ locationId: String) -> AnyCancellable {
                catalog.observeLocationSaleItems(locationId).sink {
                    receivedResults.append($0)
                    latestResult.send($0)
                }
            }
            var observation = observe("00001")
            defer { observation.cancel() }
            await expect(latestResult, matching: { $0?.isEmpty == true }) { }
            await LegacyDemoSeeder(store: ditto.store).seedAll()
            await expect(latestResult, matching: { $0?.isEmpty == false }) { }
            let prepared = try XCTUnwrap(receivedResults.first { !$0.isEmpty })
            XCTAssertEqual(prepared.count, 7)
            XCTAssertTrue(prepared.allSatisfy { $0.quantity == 20 && $0.image != nil })
            observation.cancel()
            XCTAssertTrue(ditto.store.observers.isEmpty)
            receivedResults.removeAll()
            latestResult.send(nil)
            observation = observe("00002")
            await expect(latestResult, matching: { $0?.isEmpty == false }) { }
            let other = try XCTUnwrap(receivedResults.first { !$0.isEmpty })
            XCTAssertEqual(other.count, 7)
            XCTAssertTrue(other.allSatisfy { $0.quantity == 20 && $0.image != nil })
            observation.cancel()
            let id = DocumentID(id: "00001", locationId: "00001")
            try await catalog.restart(0, id: id)
            try await catalog.increment(-2, id: id)
            receivedResults.removeAll()
            latestResult.send(nil)
            observation = observe("00001")
            await expect(latestResult, matching: { $0?.isEmpty == false }) { }
            let returned = try XCTUnwrap(receivedResults.first { !$0.isEmpty })
            XCTAssertEqual(returned.count, 7)
            XCTAssertEqual(returned.first { $0.documentId == id }?.quantity, -2)
        }
    }

    private func allItems(_ ditto: Ditto) async throws -> [SaleItem] {
        let result = try await ditto.store.execute(query: "SELECT * FROM sale_items")
        return result.decodeOrSkip()
    }

    private func expect<P: Publisher>(_ publisher: P, matching predicate: @escaping (P.Output) -> Bool, action: () -> Void) async where P.Failure == Never {
        let ready = expectation(description: "Prepared catalog delivered expected state")
        let observation = publisher.filter(predicate).prefix(1).sink { _ in ready.fulfill() }
        defer { observation.cancel() }
        action()
        await fulfillment(of: [ready], timeout: 5)
    }
}
