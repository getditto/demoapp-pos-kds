import Combine
import DittoSwift
import XCTest

@MainActor final class OrdersRepositoryTests: XCTestCase {
    func testKitchenObservationFiltersDerivedStatusAndReactsToPeerTransitions() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just<String?>("42").eraseToAnyPublisher())
            let template = try OrderFixture.load()
            func order(_ id: String, _ stage: OrderStatus, _ seconds: TimeInterval, paid: Bool = false) -> Order {
                Order(
                    documentId: DocumentID(id: id, locationId: "42"), cart: template.cart,
                    payments: paid ? template.payments : [:],
                    statusLog: ["2026-04-01T12:00:00.000Z": stage.rawValue], createdAt: Date(timeIntervalSince1970: seconds))
            }
            var ready = order("ready-new", .processed, 20, paid: true)
            ready.statusLog["2026-04-01T12:00:01.000Z"] = "inProcess"
            var delivered = order("delivered", .delivered, 30)
            delivered.statusLog["2026-04-01T12:00:01.000Z"] = "inProcess"
            var canceled = order("canceled", .canceled, 40)
            canceled.statusLog["2026-04-01T12:00:01.000Z"] = "processed"
            var empty = order("empty", .inProcess, 60)
            empty.cart = [:]
            var unknown = order("unknown", .open, 70)
            unknown.statusLog = ["2026-04-01T12:00:00.000Z": "future-status"]
            var unstarted = order("unstarted", .open, 80)
            unstarted.statusLog = [:]
            let foreign = Order(
                documentId: DocumentID(id: "preparing-new-a", locationId: "other"), cart: template.cart,
                payments: [:], statusLog: template.statusLog, createdAt: Date(timeIntervalSince1970: 90))
            for ticket in [
                ready, order("preparing-old", .inProcess, 11), delivered, order("ready-old", .processed, 10),
                order("preparing-new-b", .inProcess, 21), order("preparing-new-a", .inProcess, 22),
                canceled, order("open", .open, 50), empty, unknown, unstarted, foreign,
            ] {
                try await repository.add(order: ticket)
            }
            let observed = CurrentValueSubject<[Order]?, Never>(nil)
            let observation = repository.observeKitchenOrders("42").sink { observed.send($0) }
            defer { observation.cancel() }
            await expect(observed, matching: { $0 != nil }) { }
            let initial = try XCTUnwrap(observed.value)
            XCTAssertEqual(initial.map(\.documentId.id), ["preparing-new-a", "preparing-new-b", "ready-new", "preparing-old", "ready-old"])
            XCTAssertEqual(initial.map(\.isPaid), [false, false, true, false, false])
            XCTAssertTrue(initial.allSatisfy { $0.documentId.locationId == "42" })

            // Peer-originated writes are local mutations in this offline regression.
            try await ditto.store.execute(
                query: "UPDATE \(Order.collectionName) SET status_log.`2026-04-01T13:00:00.000Z` = 'processed' WHERE _id.id = :id AND _id.locationId = :locationId",
                arguments: ["id": "preparing-new-a", "locationId": "42"])
            await expect(observed, matching: { $0?.first { $0.documentId.id == "preparing-new-a" }?.status == .processed }) { }
            XCTAssertEqual(observed.value?.map(\.documentId.id), ["preparing-new-a", "preparing-new-b", "ready-new", "preparing-old", "ready-old"])

            try await ditto.store.execute(
                query: "UPDATE \(Order.collectionName) SET status_log.`2026-04-01T13:00:01.000Z` = 'delivered' WHERE _id.id = :id AND _id.locationId = :locationId",
                arguments: ["id": "ready-new", "locationId": "42"])
            await expect(observed, matching: { $0?.contains { $0.documentId.id == "ready-new" } == false }) { }
            XCTAssertEqual(observed.value?.map(\.documentId.id), ["preparing-new-a", "preparing-new-b", "preparing-old", "ready-old"])

            try await ditto.store.execute(
                query: "UPDATE \(Order.collectionName) UNSET cart.`line-1`, cart.`line-2` WHERE _id.id = :id AND _id.locationId = :locationId",
                arguments: ["id": "preparing-old", "locationId": "42"])
            await expect(observed, matching: { $0?.contains { $0.documentId.id == "preparing-old" } == false }) { }
            XCTAssertEqual(observed.value?.map(\.documentId.id), ["preparing-new-a", "preparing-new-b", "ready-old"])
        }
    }

    func testWritesAndObserversPreserveOrderIdentityAndLocation() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just<String?>("42").eraseToAnyPublisher())
            let original = try OrderFixture.load()
            let foreign = Order(
                documentId: DocumentID(id: original.documentId.id, locationId: "other"),
                cart: original.cart, payments: original.payments, statusLog: original.statusLog, createdAt: original.createdAt)
            let neighbor = Order(
                documentId: DocumentID(id: "another-order", locationId: "42"),
                cart: original.cart, payments: [:], statusLog: original.statusLog, createdAt: original.createdAt)
            try await repository.add(order: foreign)
            try await repository.add(order: original)
            try await repository.add(order: neighbor)
            let local = CurrentValueSubject<Order?, Never>(nil)
            let other = CurrentValueSubject<Order?, Never>(nil)
            let adjacent = CurrentValueSubject<Order?, Never>(nil)
            let localObservation = repository.observeOrder(original.documentId).sink { local.send($0) }
            let otherObservation = repository.observeOrder(foreign.documentId).sink { other.send($0) }
            let adjacentObservation = repository.observeOrder(neighbor.documentId).sink { adjacent.send($0) }
            let kitchen = KDSViewModel(ordersRepository: repository)
            defer {
                localObservation.cancel()
                otherObservation.cancel()
                adjacentObservation.cancel()
                kitchen.setVisible(false)
            }
            await expect(local, matching: { $0 == original }) { }
            await expect(other, matching: { $0 == foreign }) { }
            await expect(adjacent, matching: { $0 == neighbor }) { }
            await expect(kitchen.$orders, matching: { Set($0.map(\.documentId)) == [original.documentId, neighbor.documentId] }) {
                kitchen.setVisible(true)
            }
            let foreignPaid = foreign.addingPayment(Payment(type: .debit, amount: foreign.total), paymentId: "foreign-payment")
            try await repository.add(order: foreignPaid)
            await expect(other, matching: { $0?.payments.count == foreignPaid.payments.count }) { }
            XCTAssertEqual(local.value, original)
            XCTAssertEqual(Set(kitchen.orders.map(\.documentId)), [original.documentId, neighbor.documentId])

            let updated = original.addingCartLineItem(
                CartLineItem(saleItemId: "item-1", name: "Burger", price: Price(cents: 850), createdAt: original.createdAt),
                lineItemId: "line-3")
            try await repository.add(order: updated)
            await expect(local, matching: { $0?.cart.count == 3 }) { }
            await expect(kitchen.$orders, matching: { $0.first { $0.documentId == original.documentId }?.cart.count == 3 }) { }
            XCTAssertEqual(local.value?.cart, updated.cart)
            XCTAssertEqual(local.value?.payments, original.payments)
            XCTAssertEqual(local.value?.documentId, original.documentId)
            XCTAssertEqual(other.value?.cart, foreign.cart)
            let result = try await ditto.store.execute(query: "SELECT * FROM pos_orders")
            XCTAssertEqual(result.items.count, 3)
        }
    }

    private func expect<P: Publisher>(
        _ publisher: P, matching predicate: @escaping (P.Output) -> Bool, action: () -> Void
    ) async where P.Failure == Never {
        let ready = expectation(description: "Production order observation delivered expected state")
        let observation = publisher.filter(predicate).prefix(1).sink { _ in ready.fulfill() }
        defer { observation.cancel() }
        action()
        await fulfillment(of: [ready], timeout: 5)
    }
}
