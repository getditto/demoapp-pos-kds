import Combine
import DittoSwift
import XCTest

@MainActor final class OrdersRepositoryTests: XCTestCase {
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
