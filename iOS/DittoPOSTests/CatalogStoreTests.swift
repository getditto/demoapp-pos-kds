import Combine
import DittoSwift
import XCTest

@MainActor final class CatalogStoreTests: XCTestCase {
    func testCatalogCommandsPreserveStockAndMetadataByLocation() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let id = DocumentID(id: "coffee-'\"冰", locationId: "A")
            let other = DocumentID(id: id.id, locationId: "B")
            let metadata = SaleItemMetadata(documentId: id, name: "Coffee", imageName: "coffee", price: Price(cents: 199))
            try await repository.create(SaleItemCreation(metadata: metadata, initialQuantity: 2))
            try await repository.create(SaleItemCreation(
                metadata: SaleItemMetadata(documentId: other, name: "Other", imageName: "coffee", price: Price(cents: 250)),
                initialQuantity: 7))
            try await repository.increment(-3, id: id)
            try await repository.updateMetadata(SaleItemMetadata(documentId: id, name: "Renamed \"冰\"", imageName: "milk", price: Price(cents: 0)))
            let edited = try await read(id, from: ditto)
            XCTAssertEqual(edited.quantity, -1)
            XCTAssertEqual(edited.name, "Renamed \"冰\"")
            XCTAssertEqual(edited.price.amount, 0)
            let unchanged = try await read(other, from: ditto)
            XCTAssertEqual(unchanged.quantity, 7)
            XCTAssertEqual(unchanged.name, "Other")

            try await repository.restart(0, id: id)
            try await repository.increment(4, id: id)
            let replenished = try await read(id, from: ditto)
            XCTAssertEqual(replenished.quantity, 4)
            do {
                try await repository.restart(-1, id: id)
                XCTFail("Negative absolute quantity was accepted")
            } catch SaleItemCommands.Validation.negativeQuantity { }
            let afterRejection = try await read(id, from: ditto)
            XCTAssertEqual(afterRejection, replenished)
        }
    }

    func testExactOldAndNewInitialSeedersPreserveEditsDeletionAndFreeformItemsInEitherArrivalOrder() async throws {
        for oldFirst in [true, false] {
            try await TestDitto.withInstance { ditto in
                let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
                let snapshots = CurrentValueSubject<[SaleItem]?, Never>(nil)
                let observation = repository.observeLocationSaleItems("00001").sink(
                    receiveValue: { snapshots.send($0) })
                defer { observation.cancel() }
                _ = try await snapshot(from: snapshots, matching: { $0.isEmpty })
                let old = LegacyDemoSeeder(store: ditto.store)
                let current = DemoSeeder(store: ditto.store)
                if oldFirst { await old.seedAll() }
                await current.seedAll()
                await old.seedAll()
                let first = DocumentID(id: "00001", locationId: "00001")
                let initial = try await read(first, from: ditto)
                XCTAssertEqual(initial.quantity, oldFirst ? nil : 20)
                let all = try await ditto.store.execute(query: "SELECT * FROM sale_items")
                let rows: [SaleItem] = try all.decode()
                XCTAssertEqual(Set(rows.map(\.documentId)), Set(LegacySaleItemSeed.saleItemsForAllLocations().map(\.documentId)))
                let expectedIDs = Set(LegacySaleItemSeed.saleItemsForAllLocations().filter { $0.documentId.locationId == "00001" }.map(\.documentId))
                let visible = try await snapshot(from: snapshots, matching: { Set($0.map(\.documentId)) == expectedIDs })
                XCTAssertEqual(visible.first { $0.documentId == first }?.quantity, oldFirst ? nil : 20)

                try await repository.restart(0, id: first)
                try await repository.increment(-2, id: first)
                try await repository.updateMetadata(SaleItemMetadata(documentId: first, name: "Edited", imageName: "milk", price: Price(cents: 0)))
                let deleted = DocumentID(id: "00008", locationId: "00001")
                _ = try await ditto.store.execute(query: "DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
                                                  arguments: ["id": deleted.id, "locationId": deleted.locationId])
                let custom = SaleItemMetadata(documentId: DocumentID(id: "95f203b6-0251-4ed8-8ae2-bbcb808bf356", locationId: "00001"), name: "Custom", imageName: "coffee", price: Price(cents: 0))
                try await repository.create(SaleItemCreation(metadata: custom, initialQuantity: 3))

                await current.seedAll()
                await old.seedAll()
                await current.seedAll()
                let edited = try await read(first, from: ditto)
                XCTAssertEqual(edited.quantity, -2)
                XCTAssertEqual(edited.name, "Edited")
                XCTAssertEqual(edited.price.amount, 0)
                let retained = try await read(custom.documentId, from: ditto)
                XCTAssertEqual(retained.metadata, custom)
                XCTAssertEqual(retained.quantity, 3)
                let removed = try await ditto.store.execute(query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
                                                          arguments: ["id": deleted.id, "locationId": deleted.locationId])
                let visibleDeletedItems: [SaleItem] = removed.decodeOrSkip()
                XCTAssertTrue(visibleDeletedItems.isEmpty)
                _ = try await snapshot(from: snapshots, matching: { items in
                    !items.contains { $0.documentId == deleted }
                        && items.contains { $0.documentId == custom.documentId && $0.quantity == 3 }
                        && items.contains { $0.documentId == first && $0.name == "Edited" && $0.quantity == -2 }
                })
            }
        }
    }

    private func snapshot(from subject: CurrentValueSubject<[SaleItem]?, Never>, matching predicate: @escaping ([SaleItem]) -> Bool) async throws -> [SaleItem] {
        let ready = expectation(description: "Running catalog observer delivered expected items")
        var received: [SaleItem]?
        let observation = subject.compactMap { $0 }.filter(predicate).prefix(1).sink {
            received = $0
            ready.fulfill()
        }
        defer { observation.cancel() }
        await fulfillment(of: [ready], timeout: 5)
        return try XCTUnwrap(received)
    }

    private func read(_ id: DocumentID, from ditto: Ditto) async throws -> SaleItem {
        let result = try await ditto.store.execute(
            query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = try result.decode()
        return try XCTUnwrap(items.first)
    }

}
