import Combine
import DittoSwift
import XCTest

@MainActor final class VisibleDemoTests: XCTestCase {
    func testMidnightTabReentryKeepsTheStoredCartUntilEvictionThenStartsANewOne() async throws {
        try await TestDitto.withInstance { ditto in
            var now = try DittoWireDate.date(from: "2026-04-02T09:00:00.000Z")
            let createdAt = try DittoWireDate.date(from: "2026-04-01T23:50:00.000Z")
            let suite = "VisibleDemoTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            defaults.set(try DittoWireDate.date(from: "2026-04-01T12:00:00.000Z").timeIntervalSince1970, forKey: OrderEviction.lastRunKey)
            let location = CurrentValueSubject<Location?, Never>(Location(id: "A", name: "A"))
            let ids = location.map { $0?.id }.eraseToAnyPublisher()
            let orders = OrdersRepository(ditto: ditto, locationPublisher: ids, now: { now }, defaults: defaults, calendar: calendar)
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: ids)
            try await catalog.create(SaleItemCreation(metadata: SaleItemMetadata(
                documentId: DocumentID(id: "coffee", locationId: "A"), name: "Coffee", imageName: "coffee", price: Price(cents: 199)), initialQuantity: 2))
            let pos = POSViewModel(ordersRepository: orders, saleItemsRepository: catalog, locationPublisher: location.eraseToAnyPublisher(), locationId: { location.value?.id })
            let kitchen = KDSViewModel(ordersRepository: orders)
            await expect(pos.$saleItems, matching: { $0.count == 1 }) { pos.setVisible(true) }
            await expect(pos.$currentOrder, matching: { $0?.cart.count == 1 }) { pos.addOrderItem(pos.saleItems[0]) }
            let id = try XCTUnwrap(pos.currentOrder?.documentId)
            _ = try await ditto.store.execute(
                query: "UPDATE pos_orders SET createdAt = :date WHERE _id.id = :id AND _id.locationId = :locationId",
                arguments: ["date": DittoWireDate.string(from: createdAt), "id": id.id, "locationId": "A"])
            await expect(pos.$currentOrder, matching: { $0?.createdAt == createdAt }) { }
            let stored = try await readOrder(id, from: ditto)
            pos.setVisible(false)
            XCTAssertTrue(ditto.store.observers.isEmpty)

            await orders.runEvictionIfDue()
            let retained = try await readOrder(id, from: ditto)
            XCTAssertEqual(retained, stored)
            now = try DittoWireDate.date(from: "2026-04-03T09:00:00.000Z")
            await expect(kitchen.$orders, matching: { $0.map(\.documentId) == [id] }) { kitchen.setVisible(true) }
            kitchen.setVisible(false)
            await expect(pos.$currentOrder, matching: { $0 == stored }) { pos.setVisible(true) }
            pos.setVisible(false)
            XCTAssertTrue(ditto.store.observers.isEmpty)
            let subscription = try XCTUnwrap(ditto.sync.subscriptions.first { $0.queryString.contains("pos_orders") })
            XCTAssertEqual(subscription.queryArguments?["TTL"] as? String, "2026-04-01T00:00:00.000Z")

            await orders.runEvictionIfDue()
            XCTAssertTrue(subscription.isCancelled)
            let replacement = try XCTUnwrap(ditto.sync.subscriptions.first { $0.queryString.contains("pos_orders") })
            XCTAssertEqual(replacement.queryArguments?["TTL"] as? String, "2026-04-03T00:00:00.000Z")
            let remaining = try await ditto.store.execute(query: "SELECT * FROM pos_orders WHERE _id.locationId = :locationId", arguments: ["locationId": "A"])
            XCTAssertTrue(remaining.items.isEmpty)
            await expect(pos.$currentOrder, matching: { $0 != nil && $0?.documentId != id && $0?.cart.isEmpty == true }) { pos.setVisible(true) }
            let fresh = try await readOrder(XCTUnwrap(pos.currentOrder).documentId, from: ditto)
            XCTAssertTrue(fresh.cart.isEmpty)
        }
    }

    func testLocationChangePreservesOrdersPaidOrCanceledWhilePOSWasHidden() async throws {
        for canceled in [false, true] {
            try await TestDitto.withInstance { ditto in
                let location = CurrentValueSubject<Location?, Never>(Location(id: "A", name: "A"))
                let ids = location.map { $0?.id }.eraseToAnyPublisher()
                let orders = OrdersRepository(ditto: ditto, locationPublisher: ids)
                let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: ids)
                let metadata = SaleItemMetadata(documentId: DocumentID(id: "coffee", locationId: "A"), name: "Coffee", imageName: "coffee", price: Price(cents: 199))
                try await catalog.create(SaleItemCreation(metadata: metadata, initialQuantity: 2))
                let pos = POSViewModel(ordersRepository: orders, saleItemsRepository: catalog, locationPublisher: location.eraseToAnyPublisher(), locationId: { location.value?.id })
                await expect(pos.$saleItems, matching: { !$0.isEmpty }) { pos.setVisible(true) }
                let item = try XCTUnwrap(pos.saleItems.first)
                await expect(pos.$currentOrder, matching: { $0?.cart.count == 1 }) { pos.addOrderItem(item) }
                let outgoing = try XCTUnwrap(pos.currentOrder)
                pos.setVisible(false)
                XCTAssertTrue(ditto.store.observers.isEmpty)

                let changed = canceled
                    ? outgoing.appendingStatus(.canceled, at: Date().addingTimeInterval(2))
                    : outgoing.addingPayment(Payment(type: .cash, amount: outgoing.total, status: .complete), paymentId: "other-device")
                _ = try await ditto.store.execute(
                    query: "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json)) ON ID CONFLICT DO UPDATE_LOCAL_DIFF",
                    arguments: ["json": try changed.dittoJSONString()])
                let stored = try await readOrder(outgoing.documentId, from: ditto)
                XCTAssertTrue(stored.isPaid)
                XCTAssertFalse(try XCTUnwrap(pos.currentOrder).isPaid)

                await expect(pos.$currentOrder, matching: { $0?.documentId.locationId == "B" }) {
                    location.send(Location(id: "B", name: "B"))
                }
                let saved = try await readOrder(outgoing.documentId, from: ditto)
                XCTAssertEqual(saved, stored)
                XCTAssertTrue(ditto.store.observers.isEmpty)
            }
        }
    }

    private func readOrder(_ id: DocumentID, from ditto: Ditto) async throws -> Order {
        let result = try await ditto.store.execute(
            query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": id.id, "locationId": id.locationId])
        let orders: [Order] = try result.decode()
        return try XCTUnwrap(orders.first)
    }

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
