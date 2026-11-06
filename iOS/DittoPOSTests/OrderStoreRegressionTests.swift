import Combine
import DittoSwift
import XCTest

@MainActor final class OrderStoreRegressionTests: XCTestCase {
    func testClearCartPreservesPaymentAndStatusAndDoesNotTouchAnotherLocation() async throws {
        try await TestDitto.withInstance { ditto in
            let original = try OrderFixture.load()
            let other = Order(
                documentId: DocumentID(id: original.documentId.id, locationId: "other"),
                cart: original.cart, payments: original.payments, statusLog: original.statusLog,
                createdAt: original.createdAt)
            try await insert(original, into: ditto)
            try await insert(other, into: ditto)
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just<String?>(nil).eraseToAnyPublisher())
            try await observeChange(ditto, original, satisfying: { $0.cart.isEmpty }) {
                repository.clearCart(of: original)
            }
            let cleared = try await read(original.documentId, from: ditto)
            XCTAssertTrue(cleared.cart.isEmpty)
            XCTAssertEqual(cleared.payments, original.payments)
            XCTAssertEqual(cleared.statusLog, original.statusLog)
            XCTAssertEqual(cleared.createdAt, original.createdAt)
            let unchanged = try await read(other.documentId, from: ditto)
            XCTAssertEqual(unchanged, other)
        }
    }

    func testResetUnpaidOrderClearsLinesAndChangesOnlyItsDateAndCart() async throws {
        for empty in [false, true] {
            try await TestDitto.withInstance { ditto in
                var original = try OrderFixture.load()
                original.payments = [:]
                if empty { original.cart = [:] }
                let other = Order(
                    documentId: DocumentID(id: original.documentId.id, locationId: "other"),
                    cart: original.cart, payments: original.payments, statusLog: original.statusLog,
                    createdAt: original.createdAt)
                let resetAt = try DittoWireDate.date(from: "2026-05-01T10:20:30.123Z")
                try await insert(original, into: ditto)
                try await insert(other, into: ditto)
                let repository = OrdersRepository(
                    ditto: ditto, locationPublisher: Just<String?>(nil).eraseToAnyPublisher(), now: { resetAt })
                try await repository.resetUnpaidOrder(original.documentId)
                let reset = try await read(original.documentId, from: ditto)
                XCTAssertEqual(reset.createdAt, resetAt)
                XCTAssertTrue(reset.cart.isEmpty)
                XCTAssertEqual(reset.payments, original.payments)
                XCTAssertEqual(reset.statusLog, original.statusLog)
                let unchanged = try await read(other.documentId, from: ditto)
                XCTAssertEqual(unchanged, other)
            }
        }
    }

    func testLocalEvictionIncludesMidnightAndUnpaidOrdersButRetainsLaterRecords() async throws {
        try await TestDitto.withInstance { ditto in
            let midnight = try DittoWireDate.date(from: "2026-04-01T00:00:00.000Z")
            let template = try OrderFixture.load()
            for (id, date) in [
                ("older", midnight.addingTimeInterval(-1)), ("midnight", midnight),
                ("after", midnight.addingTimeInterval(0.001)),
            ] {
                let order = Order(
                    documentId: DocumentID(id: id, locationId: "42"), cart: template.cart, payments: [:],
                    statusLog: template.statusLog, createdAt: date)
                try await insert(order, into: ditto)
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let suite = "OrderEvictionTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let now = midnight.addingTimeInterval(12 * 60 * 60)
            let repository = OrdersRepository(
                ditto: ditto, locationPublisher: Just<String?>(nil).eraseToAnyPublisher(), now: { now }, defaults: defaults, calendar: calendar)
            try await repository.runEvictionIfDue()
            let result = try await ditto.store.execute(
                query: "SELECT * FROM pos_orders WHERE _id.locationId = :locationId", arguments: ["locationId": "42"])
            let remaining: [Order] = try result.decode()
            XCTAssertEqual(remaining.map(\.documentId.id), ["after"])
            XCTAssertEqual(defaults.double(forKey: "v2.lastEvictionAt"), now.timeIntervalSince1970)
        }
    }

    private func insert(_ order: Order, into ditto: Ditto) async throws {
        _ = try await ditto.store.execute(
            query: "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json))",
            arguments: ["json": try order.dittoJSONString()])
    }

    private func read(_ id: DocumentID, from ditto: Ditto) async throws -> Order {
        let result = try await ditto.store.execute(
            query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": id.id, "locationId": id.locationId]
        )
        let orders: [Order] = try result.decode()
        return try XCTUnwrap(orders.first)
    }

    private func observeChange(
        _ ditto: Ditto, _ order: Order, satisfying predicate: @escaping @Sendable (Order) -> Bool, action: () -> Void
    ) async throws {
        let changed = expectation(description: "Observed order change")
        changed.assertForOverFulfill = false
        let observer = try ditto.store.registerObserver(
            query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": order.documentId.id, "locationId": order.documentId.locationId],
            deliverOn: .main,
            handler: { result in
                guard let orders: [Order] = try? result.decode(), let saved = orders.first, predicate(saved) else {
                    return
                }
                changed.fulfill()
            }
        )
        defer { observer.cancel() }
        action()
        await fulfillment(of: [changed], timeout: 5)
    }
}
