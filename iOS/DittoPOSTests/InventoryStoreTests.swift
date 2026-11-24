import Combine
import DittoSwift
import XCTest

@MainActor final class InventoryStoreTests: XCTestCase {
    func testManualInventoryObservesScopedStockAndCancelsDraftsAcrossVisibilityAndLocation() async throws {
        try await TestDitto.withInstance { ditto in
            let locations = CurrentValueSubject<String?, Never>("A")
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: locations.eraseToAnyPublisher())
            let local = DocumentID(id: "coffee", locationId: "A")
            let foreign = DocumentID(id: local.id, locationId: "B")
            for (id, quantity) in [(local, Int64(2)), (foreign, Int64(7))] {
                try await repository.create(SaleItemCreation(metadata: SaleItemMetadata(documentId: id, name: "Coffee", price: Price(cents: 195)), initialQuantity: quantity))
            }
            let model = InventoryModel(repository: repository, locationPublisher: locations.eraseToAnyPublisher())
            defer { model.setVisible(false) }
            XCTAssertTrue(ditto.store.observers.isEmpty)
            model.setVisible(true)
            await expect(model, quantity: 2)
            XCTAssertEqual(model.state.items.map(\.documentId), [local])
            try await model.step(-1, id: local)
            await expect(model, quantity: 1)
            try await model.step(1, id: local)
            await expect(model, quantity: 2)
            try await repository.increment(-5, id: local)
            await expect(model, quantity: -3)
            try await model.step(-1, id: local)
            try await assertQuantity(-3, id: local, ditto: ditto)
            try await model.step(1, id: local)
            await expect(model, quantity: -2)
            model.beginEditing(local); model.updateText("6")
            try await assertQuantity(-2, id: local, ditto: ditto)
            model.cancelEditing()
            try await model.submit()
            try await assertQuantity(-2, id: local, ditto: ditto)
            model.beginEditing(local); model.updateText("6")
            try await model.submit()
            await expect(model, quantity: 6)
            model.beginEditing(local); model.updateText("99")
            model.setVisible(false)
            XCTAssertNil(model.state.edit)
            XCTAssertTrue(model.state.items.isEmpty)
            XCTAssertTrue(ditto.store.observers.isEmpty)
            XCTAssertTrue(ditto.sync.subscriptions.contains { !$0.isCancelled })
            try await repository.restart(9, id: local)
            model.setVisible(true)
            XCTAssertTrue(model.state.isLoading)
            await expect(model, quantity: 9)
            model.beginEditing(local); model.updateText("88")
            locations.send("B")
            XCTAssertTrue(model.state.isLoading)
            XCTAssertNil(model.state.edit)
            try await model.submit()
            await expect(model, quantity: 7)
            XCTAssertEqual(model.state.items.map(\.documentId), [foreign])
            try await assertQuantity(9, id: local, ditto: ditto)
            model.beginEditing(foreign)
            try await ditto.store.execute(query: "DELETE FROM \(SaleItem.collectionName) WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": foreign.id, "locationId": "B"])
            let empty = expectation(description: "Deleted item disappears with its draft")
            let observation = model.$state.filter { !$0.isLoading && $0.items.isEmpty && $0.edit == nil }.prefix(1).sink { _ in empty.fulfill() }
            await fulfillment(of: [empty], timeout: 5)
            observation.cancel()
            let orders = try await ditto.store.execute(query: "SELECT * FROM \(Order.collectionName)")
            XCTAssertTrue(orders.items.isEmpty)
        }
    }

    private func assertQuantity(_ expected: Int64, id: DocumentID, ditto: Ditto) async throws {
        let actual = try await quantity(id, ditto)
        XCTAssertEqual(actual, expected)
    }
    private func quantity(_ id: DocumentID, _ ditto: Ditto) async throws -> Int64 {
        let result = try await ditto.store.execute(query: "SELECT * FROM \(SaleItem.collectionName) WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = try result.decode()
        return try XCTUnwrap(items.first).quantity
    }
    private func expect(_ model: InventoryModel, quantity: Int64) async {
        let received = expectation(description: "Inventory shows observed quantity \(quantity)")
        let observation = model.$state.filter { !$0.isLoading && $0.items.first?.quantity == quantity }.prefix(1).sink { _ in received.fulfill() }
        await fulfillment(of: [received], timeout: 5)
        observation.cancel()
    }
}
