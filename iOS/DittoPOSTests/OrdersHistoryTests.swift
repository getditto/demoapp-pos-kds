import Combine
import DittoSwift
import XCTest

@MainActor final class OrdersHistoryTests: XCTestCase {
    func testEachProductionQueryFiltersBeforeCountingAndPaging() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just<String?>(nil).eraseToAnyPublisher())
            let fixture = try OrderFixture.load()
            for index in 0..<55 {
                try await repository.add(order: Order(documentId: DocumentID(id: "empty-\(index)", locationId: "A"), cart: [:], payments: [:], statusLog: fixture.statusLog, createdAt: .distantFuture))
                try await repository.add(order: Order(documentId: DocumentID(id: "paid", locationId: "other-\(index)"), cart: fixture.cart, payments: fixture.payments, statusLog: fixture.statusLog, createdAt: .distantFuture))
            }
            for id in ["zero-unpaid", "paid"] {
                let cart = fixture.cart.mapValues { CartLineItem(saleItemId: $0.saleItemId, name: $0.name, price: Price(cents: 0), qty: $0.qty, createdAt: $0.createdAt, image: $0.image) }
                try await repository.add(order: Order(documentId: DocumentID(id: id, locationId: "A"), cart: cart, payments: id == "paid" ? fixture.payments : [:], statusLog: fixture.statusLog, createdAt: fixture.createdAt))
            }
            let page = try await ditto.store.execute(query: OrdersHistoryQuery.page, arguments: ["locationId": "A", "offset": 0])
            let orders: [Order] = try page.decode()
            XCTAssertEqual(orders.map(\.documentId.id), ["paid", "zero-unpaid"])
            let count = try await ditto.store.execute(query: OrdersHistoryQuery.count, arguments: ["locationId": "A"])
            let totals: [OrdersHistoryQuery.Count] = try count.decode()
            XCTAssertEqual(totals.map(\.total), [2])
        }
    }

    func testMatchingLocalQueriesDrivePagesCartEligibilityAndCleanup() async throws {
        try await TestDitto.withInstance { ditto in
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just<String?>(nil).eraseToAnyPublisher(),
                                              now: { Date(timeIntervalSince1970: 1_775_131_200) },
                                              defaults: UserDefaults(suiteName: UUID().uuidString)!, calendar: Calendar(identifier: .gregorian))
            let fixture = try OrderFixture.load()
            let old = try DittoWireDate.date(from: "2026-03-31T12:00:00Z")
            let current = try DittoWireDate.date(from: "2026-04-02T12:00:00Z")
            func order(_ index: Int, location: String = "A", empty: Bool = false) -> Order {
                Order(documentId: DocumentID(id: String(format: "%08d", index), locationId: location),
                      cart: empty ? [:] : fixture.cart.mapValues { line in
                          CartLineItem(saleItemId: line.saleItemId, name: line.name,
                                       price: index == 0 ? Price(cents: 0) : line.price, qty: line.qty, createdAt: line.createdAt, image: line.image)
                      }, payments: index % 2 == 0 ? fixture.payments : [:],
                      statusLog: fixture.statusLog, createdAt: index < 50 ? old : current)
            }
            // Repeated IDs in another location and empty drafts must not consume page slots.
            for index in 0..<105 { try await repository.add(order: order(index, location: "B")) }
            for index in 200..<255 { try await repository.add(order: order(index, empty: true)) }
            let history = OrdersHistory(repository: repository)
            history.setLocation("A")
            history.setVisible(true)
            defer { history.setVisible(false) }
            await expect(history) { $0.total == 0 && $0.orders.isEmpty }
            XCTAssertEqual(ditto.store.observers.count, 2)
            var inserted = 0
            for total in [49, 50, 51, 100, 101] {
                for index in inserted..<total { try await repository.add(order: order(index)) }
                inserted = total
                await expect(history) { $0.total == total && $0.orders.count == min(50, total) }
                XCTAssertEqual(history.state.totalPages, total <= 50 ? 1 : total <= 100 ? 2 : 3)
                XCTAssertTrue(history.state.orders.allSatisfy { $0.documentId.locationId == "A" && !$0.cart.isEmpty })
            }
            let countObserver = try XCTUnwrap(ditto.store.observers.first { $0.queryString.contains("COUNT") })
            history.next()
            await expect(history) { $0.pageIndex == 1 && $0.orders.count == 50 }
            XCTAssertFalse(countObserver.isCancelled)
            history.next()
            await expect(history) { $0.pageIndex == 2 && $0.orders.map(\.documentId.id) == ["00000049"] }
            XCTAssertFalse(history.state.canNext)
            XCTAssertTrue(history.state.orders[0].createdAt < current)
            _ = try await ditto.store.execute(query: "DELETE FROM \(Order.collectionName) WHERE _id.locationId = :locationId AND _id.id = :id", arguments: ["locationId": "A", "id": "00000049"])
            await expect(history) { $0.total == 100 && $0.pageIndex == 1 && $0.orders.count == 50 }
            try await repository.add(order: order(101))
            await expect(history) { $0.total == 101 && $0.pageIndex == 1 && $0.canNext }
            try await repository.add(order: order(200))
            await expect(history) { $0.total == 102 }
            repository.clearCart(of: order(200))
            await expect(history) { $0.total == 101 }
            history.previous()
            await expect(history) { $0.pageIndex == 0 && $0.orders.count == 50 }
            // Same-date ties use full IDs, rather than depending on observer delivery order.
            XCTAssertEqual(history.state.orders.prefix(3).map(\.documentId.id), ["00000050", "00000051", "00000052"])
            history.next()
            history.next()
            await expect(history) { $0.pageIndex == 2 && $0.orders.count == 1 }
            try await repository.runEvictionIfDue()
            await expect(history) { $0.total == 52 && $0.pageIndex == 1 && $0.orders.count == 2 }
            XCTAssertTrue(history.state.orders.allSatisfy { $0.createdAt == current })
            history.setVisible(false)
            XCTAssertEqual(ditto.store.observers.count, 0)
            history.setVisible(true)
            await expect(history) { $0.total == 52 && $0.pageIndex == 1 && $0.orders.count == 2 }
            history.setLocation("B")
            await expect(history) { $0.total == 55 && $0.pageIndex == 0 && $0.orders.count == 50 }
        }
    }

    func testIndependentCallbackOrderClampsRetainedPageAndOnlyReplacesPageObservation() throws {
        let order = try OrderFixture.load()
        let counts = PassthroughSubject<Int, Never>()
        var pages: [PassthroughSubject<[Order], Never>] = []
        var countStarts = 0
        var countStops = 0
        var pageStops = 0
        let history = OrdersHistory(observePage: { _, _ in
            let page = PassthroughSubject<[Order], Never>()
            pages.append(page)
            return page.handleEvents(receiveCancel: { pageStops += 1 }).eraseToAnyPublisher()
        }, observeCount: { _ in
            countStarts += 1
            return counts.handleEvents(receiveCancel: { countStops += 1 }).eraseToAnyPublisher()
        })
        history.setLocation("A")
        history.setVisible(true)
        XCTAssertTrue(history.state.isLoading)
        pages[0].send([order])
        XCTAssertTrue(history.state.isLoading)
        counts.send(0)
        XCTAssertFalse(history.state.isLoading)
        XCTAssertTrue(history.state.orders.isEmpty)
        counts.send(101)
        XCTAssertEqual(history.state.orders, [order])
        history.next(); history.next()
        XCTAssertTrue(history.state.isLoading)
        XCTAssertEqual(countStarts, 1)
        XCTAssertEqual(pageStops, 2)
        history.setVisible(false)
        XCTAssertEqual(countStops, 1)
        pages[2].send([order]); counts.send(500)
        XCTAssertNil(history.state.total)
        XCTAssertTrue(history.state.orders.isEmpty)
        history.setVisible(true)
        counts.send(49)
        XCTAssertEqual(history.state.pageIndex, 0)
        pages[3].send([order])
        XCTAssertTrue(history.state.isLoading)
        XCTAssertTrue(history.state.orders.isEmpty)
        pages[4].send([order])
        XCTAssertFalse(history.state.isLoading)
        XCTAssertEqual(history.state.orders, [order])
        XCTAssertEqual(countStarts, 2)
        history.setLocation("B")
        XCTAssertEqual(history.state.pageIndex, 0)
        XCTAssertNil(history.state.total)
        history.setVisible(false)
    }

    private func expect(_ history: OrdersHistory, matching predicate: @escaping (OrdersHistoryState) -> Bool) async {
        let ready = expectation(description: "Orders page and count match")
        let observation = history.$state.filter(predicate).prefix(1).sink { _ in ready.fulfill() }
        defer { observation.cancel() }
        await fulfillment(of: [ready], timeout: 5)
    }
}
