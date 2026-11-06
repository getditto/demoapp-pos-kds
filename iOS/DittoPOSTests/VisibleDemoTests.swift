import Combine
import DittoSwift
import XCTest

@MainActor final class VisibleDemoTests: XCTestCase {
    func testTabsOwnOnlyTheirQueriesAndReturnToTheSameCartWithFreshCatalogAndOrderData() async throws {
        try await TestDitto.withInstance { ditto in
            let baseline = ditto.store.observers.count
            let location = CurrentValueSubject<Location?, Never>(Location(id: "A", name: "A"))
            let ids = location.map { $0?.id }.eraseToAnyPublisher()
            let orders = OrdersRepository(ditto: ditto, locationPublisher: ids, now: { Date(timeIntervalSince1970: 0) })
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: ids)
            let metadata = SaleItemMetadata(documentId: DocumentID(id: "coffee", locationId: "A"), name: "Original", imageName: "coffee", price: Price(cents: 199))
            try await catalog.create(SaleItemCreation(metadata: metadata, initialQuantity: 0))
            try await catalog.create(SaleItemCreation(metadata: SaleItemMetadata(
                documentId: DocumentID(id: "coffee", locationId: "B"), name: "Other location", imageName: "milk", price: Price(cents: 250)), initialQuantity: 7))
            let pos = POSViewModel(ordersRepository: orders, saleItemsRepository: catalog, locationPublisher: location.eraseToAnyPublisher(), locationId: { location.value?.id })
            let kitchen = KDSViewModel(ordersRepository: orders)
            XCTAssertEqual(ditto.store.observers.count, baseline)

            await expect(pos.$saleItems, matching: { $0.map(\.name) == ["Original"] }) { pos.setVisible(true) }
            let firstID = try XCTUnwrap(pos.currentOrder?.documentId)
            XCTAssertEqual(ditto.store.observers.count, baseline + 2)
            let item = try XCTUnwrap(pos.saleItems.first)
            // Stock-aware sales arrive in137; zero must not disable today's POS.
            await expect(pos.$currentOrder, matching: { $0?.cart.count == 1 }) { pos.addOrderItem(item) }
            pos.setVisible(false)
            XCTAssertEqual(ditto.store.observers.count, baseline)

            try await catalog.updateMetadata(SaleItemMetadata(documentId: metadata.documentId, name: "Renamed", imageName: "milk", price: Price(cents: 0)))
            await expect(kitchen.$orders, matching: { $0.count == 1 }) { kitchen.setVisible(true) }
            XCTAssertEqual(ditto.store.observers.count, baseline + 1)
            XCTAssertFalse(ditto.store.observers.contains { $0.queryString.contains("sale_items") })
            let ticket = try XCTUnwrap(kitchen.orders.first)
            await expect(kitchen.$orders, matching: { $0.first?.status == .processed }) { orders.updateStatus(of: ticket, with: .processed) }
            kitchen.setVisible(false)
            XCTAssertEqual(ditto.store.observers.count, baseline)

            await expect(pos.$saleItems, matching: { $0.map(\.name) == ["Renamed"] }) { pos.setVisible(true) }
            await expect(pos.$currentOrder, matching: { $0?.status == .processed }) { }
            XCTAssertEqual(pos.currentOrder?.documentId, firstID)
            XCTAssertEqual(pos.currentOrder?.cart.values.first?.name, "Original")
            XCTAssertEqual(pos.currentOrder?.cart.values.first?.price.amount, 199)
            XCTAssertEqual(pos.saleItems.first?.quantity, 0)
            XCTAssertEqual(ditto.store.observers.count, baseline + 2)

            await expect(pos.$currentOrder, matching: { $0?.cart.isEmpty == true }) { pos.clearCurrentOrderCart() }
            let renamed = try XCTUnwrap(pos.saleItems.first)
            await expect(pos.$currentOrder, matching: { $0?.cart.count == 1 }) { pos.addOrderItem(renamed) }
            await expect(pos.$currentOrder, matching: { $0?.isPaid == true }) { pos.payCurrentOrder() }
            await expect(pos.$currentOrder, matching: { $0?.documentId != firstID && $0?.cart.isEmpty == true }) { }
            XCTAssertEqual(ditto.store.observers.count, baseline + 2)

            await expect(pos.$saleItems, matching: { $0.map(\.name) == ["Other location"] }) {
                location.send(Location(id: "B", name: "B"))
            }
            XCTAssertEqual(pos.currentOrder?.documentId.locationId, "B")
            XCTAssertTrue(pos.saleItems.allSatisfy { $0.documentId.locationId == "B" })
            await expect(pos.$currentOrder, matching: { $0 == nil }) { location.send(nil) }
            XCTAssertTrue(pos.saleItems.isEmpty)
            XCTAssertEqual(ditto.store.observers.count, baseline)
            await expect(pos.$saleItems, matching: { $0.map(\.name) == ["Other location"] }) {
                location.send(Location(id: "B", name: "B"))
            }
            pos.setVisible(false)
            XCTAssertEqual(ditto.store.observers.count, baseline)
            XCTAssertEqual(ditto.sync.subscriptions.count, 2)
            kitchen.setVisible(true)
            XCTAssertEqual(ditto.store.observers.count, baseline + 1)
            location.send(nil)
            XCTAssertEqual(ditto.store.observers.count, baseline)
            XCTAssertTrue(kitchen.orders.isEmpty)
            XCTAssertEqual(ditto.sync.subscriptions.count, 0)
        }
    }

    private func expect<P: Publisher>(
        _ publisher: P, matching predicate: @escaping (P.Output) -> Bool, action: () -> Void
    ) async where P.Failure == Never {
        let ready = expectation(description: "Production view model delivered expected state")
        let observation = publisher.filter(predicate).prefix(1).sink { _ in ready.fulfill() }
        defer { observation.cancel() }
        action()
        await fulfillment(of: [ready], timeout: 5)
    }
}
