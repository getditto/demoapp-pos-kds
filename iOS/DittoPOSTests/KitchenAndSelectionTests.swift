import XCTest

final class KitchenAndSelectionTests: XCTestCase {
    func testKitchenAdvancesThroughExistingStagesAndStopsAtTerminalStates() {
        XCTAssertEqual(OrderStatus.inProcess.next, .processed)
        XCTAssertEqual(OrderStatus.processed.next, .delivered)
        XCTAssertNil(OrderStatus.delivered.next)
        XCTAssertNil(OrderStatus.canceled.next)
    }

    func testObservedSelectionUsesBothOrderAndLocationAndRejectsMissingOrders() throws {
        let local = try OrderFixture.load()
        var foreign = local
        foreign = Order(
            documentId: DocumentID(id: local.documentId.id, locationId: "other"), cart: foreign.cart,
            payments: foreign.payments, statusLog: foreign.statusLog, createdAt: foreign.createdAt)
        XCTAssertEqual(
            OrderSelection.observedOrder(id: local.documentId.id, locationId: "42", in: [foreign, local]), local)
        XCTAssertNil(OrderSelection.observedOrder(id: local.documentId.id, locationId: "42", in: [foreign]))
        XCTAssertNil(OrderSelection.observedOrder(id: local.documentId.id, locationId: "42", in: []))
        XCTAssertNil(OrderSelection.observedOrder(id: nil, locationId: "42", in: [local]))
        XCTAssertNil(OrderSelection.observedOrder(id: local.documentId.id, locationId: nil, in: [local]))
    }
}
