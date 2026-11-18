import Combine
import DittoSwift
import XCTest

@MainActor final class CatalogStoreTests: XCTestCase {
    func testCatalogCommandsPreserveStockAndMetadataByLocation() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let id = DocumentID(id: "coffee-'\"iced", locationId: "A")
            let other = DocumentID(id: id.id, locationId: "B")
            let metadata = SaleItemMetadata(documentId: id, name: "Coffee", price: Price(cents: 199))
            try await repository.create(SaleItemCreation(metadata: metadata, initialQuantity: 2))
            try await repository.create(SaleItemCreation(
                metadata: SaleItemMetadata(documentId: other, name: "Other", price: Price(cents: 250)),
                initialQuantity: 7))
            try await repository.increment(-3, id: id)
            let replacement = SaleItemMetadata(documentId: id, name: "Renamed \"iced\"", price: Price(cents: 0))
            try await repository.updateMetadata(replacement)
            let edited = try await read(id, from: ditto)
            XCTAssertEqual(edited.quantity, -1)
            XCTAssertEqual(edited.metadata, replacement)
            let unchanged = try await read(other, from: ditto)
            XCTAssertEqual(unchanged.quantity, 7)
            XCTAssertEqual(unchanged.name, "Other")

            try await repository.restart(0, id: id)
            try await repository.increment(4, id: id)
            let replenished = try await read(id, from: ditto)
            XCTAssertEqual(replenished.quantity, 4)
            XCTAssertEqual(replenished.metadata, replacement)
            do {
                try await repository.restart(-1, id: id)
                XCTFail("Negative absolute quantity was accepted")
            } catch SaleItemCommands.Validation.negativeQuantity { }
            let afterRejection = try await read(id, from: ditto)
            XCTAssertEqual(afterRejection, replenished)
        }
    }

    func testStarterAttachmentsAndReseedingPreserveCatalogChanges() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let seeder = DemoSeeder(store: ditto.store)
            await seeder.seedAll()
            let result = try await ditto.store.execute(query: "SELECT * FROM sale_items_v2")
            let seeded: [SaleItem] = try result.decode()
            let expected = SaleItemSeed.saleItemsForAllLocations()
            XCTAssertEqual(Set(seeded.map(\.metadata)), Set(expected.map(\.metadata)))
            for item in seeded {
                XCTAssertEqual(item.quantity, 20)
                let data = try StockPhotos.data(for: item.documentId.id)
                let photo = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: ditto.store)
                XCTAssertEqual(item.image, PhotoAttachments.reference(to: photo))
            }

            let editedId = DocumentID(id: "00001", locationId: "00001")
            let noPhotoId = DocumentID(id: "00013", locationId: "00001")
            let deletedId = DocumentID(id: "00008", locationId: "00001")
            let changedPhoto = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            try await repository.increment(-22, id: editedId)
            try await repository.updateMetadata(SaleItemMetadata(documentId: editedId, name: "Edited", price: Price(cents: 0)))
            try await PhotoAttachments.replace(changedPhoto, for: editedId, executor: ditto.store)
            try await repository.restart(0, id: noPhotoId)
            try await PhotoAttachments.remove(for: noPhotoId, executor: ditto.store)
            _ = try await ditto.store.execute(
                query: "DELETE FROM sale_items_v2 WHERE _id.id = :id AND _id.locationId = :locationId",
                arguments: ["id": deletedId.id, "locationId": deletedId.locationId])
            let custom = SaleItemMetadata(documentId: DocumentID(id: "custom", locationId: "00001"), name: "Custom", price: Price(cents: 0))
            try await repository.create(SaleItemCreation(metadata: custom, initialQuantity: 3))
            let observedItems = CurrentValueSubject<[SaleItem]?, Never>(nil)
            let observation = repository.observeLocationSaleItems("00001").sink { observedItems.send($0) }
            defer { observation.cancel() }
            await seeder.seedAll()
            await seeder.seedAll()

            let edited = try await read(editedId, from: ditto)
            XCTAssertEqual(edited.quantity, -2)
            XCTAssertEqual(edited.name, "Edited")
            XCTAssertEqual(edited.price.amount, 0)
            XCTAssertEqual(edited.image, PhotoAttachments.reference(to: changedPhoto))
            let noPhoto = try await read(noPhotoId, from: ditto)
            XCTAssertEqual(noPhoto.quantity, 0)
            XCTAssertNil(noPhoto.image)
            let retainedCustom = try await read(custom.documentId, from: ditto)
            XCTAssertEqual(retainedCustom.metadata, custom)
            XCTAssertEqual(retainedCustom.quantity, 3)
            XCTAssertNil(retainedCustom.image)
            let visible = try await waitForItems(from: observedItems, matching: { items in
                !items.contains { $0.documentId == deletedId }
                    && items.contains { $0.documentId == custom.documentId }
            })
            XCTAssertEqual(visible.count, 7)
            XCTAssertTrue(visible.allSatisfy { $0.documentId.locationId == "00001" })
        }
    }

    func testCutoverIgnoresOldCollectionsAndLeavesTheirDocumentsUntouched() async throws {
        try await TestDitto.withInstance { ditto in
            let order = try OrderFixture.load()
            let oldOrderJSON = try order.dittoJSONString()
            _ = try await ditto.store.execute(query: "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json))", arguments: ["json": oldOrderJSON])
            _ = try await ditto.store.execute(query: """
                INSERT INTO sale_items DOCUMENTS ({"_id": {"id": "00001", "locationId": "00001"}, "name": "Old item", "quantity": 99})
                """)
            await DemoSeeder(store: ditto.store).seedAll()
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let observedItems = CurrentValueSubject<[SaleItem]?, Never>(nil)
            let catalogObservation = catalog.observeLocationSaleItems("00001").sink { observedItems.send($0) }
            defer { catalogObservation.cancel() }
            let items = try await waitForItems(from: observedItems, matching: { !$0.isEmpty })
            XCTAssertEqual(items.first { $0.documentId.id == "00001" }?.name, "Burger")
            let orders = OrdersRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let absent = expectation(description: "An old saved order ID is absent from the new collection")
            let orderObservation = orders.observeOrder(order.documentId).prefix(1).sink {
                XCTAssertNil($0)
                absent.fulfill()
            }
            await fulfillment(of: [absent], timeout: 5)
            orderObservation.cancel()
            try await orders.add(order: order)
            let current = try await ditto.store.execute(query: "SELECT * FROM pos_orders_v2")
            let currentOrders: [Order] = try current.decode()
            XCTAssertEqual(currentOrders, [order])
            try await catalog.increment(-1, id: DocumentID(id: "00001", locationId: "00001"))
            let oldItem = try await ditto.store.execute(query: "SELECT name, quantity FROM sale_items")
            XCTAssertEqual(oldItem.items.first?.value["name"] as? String, "Old item")
            XCTAssertEqual(oldItem.items.first?.value["quantity"] as? Int, 99)
            let oldOrders = try await ditto.store.execute(query: "SELECT * FROM pos_orders")
            let untouched: [Order] = try oldOrders.decode()
            XCTAssertEqual(untouched, [order])
        }
    }

    private func waitForItems(from subject: CurrentValueSubject<[SaleItem]?, Never>, matching predicate: @escaping ([SaleItem]) -> Bool) async throws -> [SaleItem] {
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
            query: "SELECT * FROM sale_items_v2 WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = try result.decode()
        return try XCTUnwrap(items.first)
    }

}
