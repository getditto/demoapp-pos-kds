import XCTest

enum OrderFixture {
    static func data() throws -> Data {
        let url = try XCTUnwrap(
            Bundle(for: OrderModelTests.self).url(
                forResource: "order", withExtension: "json", subdirectory: "Fixtures"
            ))
        return try Data(contentsOf: url)
    }

    static func load() throws -> Order {
        try JSONDecoder.ditto.decode(Order.self, from: data())
    }
}

final class OrderModelTests: XCTestCase {
    /// The order number shown on POS and KDS is the first 8 characters of the
    /// ID in uppercase, so orders created on Android (lowercase UUIDs) and iOS
    /// (uppercase UUIDs) look the same on every device.
    func testTitleIsTheFirstEightCharactersOfTheIdInUppercase() {
        func order(id: String) -> Order {
            Order(documentId: DocumentID(id: id, locationId: "42"), cart: [:], payments: [:], statusLog: [:], createdAt: Date())
        }
        XCTAssertEqual(order(id: "fe9b5646-6319-4f20-b4e6-3ae2841e395e").title, "FE9B5646")
        XCTAssertEqual(order(id: "D8161832-0C3A-4E2B-9F4D-5A6B7C8D9E0F").title, "D8161832")
        XCTAssertEqual(order(id: "ab12").title, "AB12")
    }

    func testKnownWireFixtureDecodesAndEncodesWithoutLosingMapsOrEscaping() throws {
        let order = try OrderFixture.load()
        XCTAssertEqual(order.documentId, DocumentID(id: "order-'\"☕", locationId: "42"))
        XCTAssertEqual(order.cart["line-1"]?.name, "Coffee \"冰\"")
        XCTAssertEqual(order.status, .inProcess)
        XCTAssertTrue(order.isPaid)
        let encoded = try JSONEncoder.ditto.encode(order)
        let expected = try XCTUnwrap(JSONSerialization.jsonObject(with: OrderFixture.data()) as? NSDictionary)
        let actual = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
        XCTAssertEqual(actual, expected)
    }

    func testTotalsCountEveryUnitAndSummaryCombinesRepeatedNames() throws {
        let order = try OrderFixture.load()
        XCTAssertEqual(order.totalCents, 1097)  // 3 × 199 + 2 × 250
        XCTAssertEqual(order.summary, ["Coffee \"冰\"": 5])
        XCTAssertEqual(order.sortedLineItems.map(\.price.amount), [199, 250])
    }

    func testAddingAnotherLinePreservesReceiptAndPaymentHistory() throws {
        let original = try OrderFixture.load()
        let item = CartLineItem(
            saleItemId: "coffee-冰", name: "New coffee", imageName: "coffee", price: Price(cents: 100), qty: 2)
        let updated = original.addingCartLineItem(item, lineItemId: "line-3")
        XCTAssertEqual(updated.totalCents, 1297)
        XCTAssertEqual(updated.cart["line-1"], original.cart["line-1"])
        XCTAssertEqual(updated.cart["line-2"], original.cart["line-2"])
        XCTAssertEqual(updated.payments, original.payments)
        XCTAssertEqual(updated.documentId, original.documentId)
        XCTAssertEqual(updated.createdAt, original.createdAt)
        for (key, value) in original.statusLog { XCTAssertEqual(updated.statusLog[key], value) }
        XCTAssertEqual(original.cart.count, 2)
    }

    func testPaymentAndStatusMutationsPreserveOtherMaps() throws {
        let original = try OrderFixture.load()
        let payment = Payment(type: .debit, amount: Price(cents: 847))
        let paid = original.addingPayment(payment, paymentId: "debit-2")
        XCTAssertEqual(paid.payments.count, 2)
        XCTAssertEqual(paid.payments["cash-1"], original.payments["cash-1"])
        XCTAssertEqual(paid.cart, original.cart)
        XCTAssertEqual(paid.statusLog, original.statusLog)
        let changed = paid.appendingStatus(.processed, at: Date(timeIntervalSince1970: 1_775_044_810))
        XCTAssertEqual(changed.status, .processed)
        XCTAssertEqual(changed.cart, paid.cart)
        XCTAssertEqual(changed.payments, paid.payments)
        XCTAssertEqual(changed.statusLog.count, original.statusLog.count + 1)
    }

    func testZeroDollarCartStillRequiresAPaymentEntryAndCanceledIsTerminal() {
        let item = CartLineItem(saleItemId: "free", name: "Free sample", imageName: "", price: Price(cents: 0), qty: 2)
        let order = Order.new(locationId: "42").addingCartLineItem(item, lineItemId: "free-1")
        XCTAssertEqual(order.totalCents, 0)
        XCTAssertFalse(order.isPaid)
        XCTAssertTrue(order.addingPayment(Payment(type: .cash, amount: Price(cents: 0)), paymentId: "zero").isPaid)
        XCTAssertTrue(order.appendingStatus(.canceled).isPaid)
    }

    func testLineSnapshotRetainsOriginalMetadataAfterCatalogReplacement() {
        var catalog = SaleItem.seed(id: "coffee", locationId: "42", name: "Original", imageName: "coffee", cents: 199)
        let line = CartLineItem(from: catalog, qty: 3)
        catalog = SaleItem.seed(id: "coffee", locationId: "42", name: "Renamed", imageName: "tea", cents: 999)
        XCTAssertEqual(line.name, "Original")
        XCTAssertEqual(line.price.amount, 199)
        XCTAssertEqual(line.imageName, "coffee")
        XCTAssertEqual(line.qty, 3)
        XCTAssertEqual(CartLineItem(from: catalog).price.amount, 999)
    }
}
