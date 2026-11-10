import XCTest

final class KitchenAndSelectionTests: XCTestCase {
    func testKitchenGroupsStagesNewestFirstKeepsUnpaidAndHidesEmptyOrders() throws {
        let template = try OrderFixture.load()
        func order(_ id: String, _ stage: OrderStatus, _ seconds: TimeInterval, paid: Bool = false) -> Order {
            Order(
                documentId: DocumentID(id: id, locationId: "42"), cart: template.cart,
                payments: paid ? template.payments : [:],
                statusLog: ["2026-04-01T12:00:00.000Z": stage.rawValue], createdAt: Date(timeIntervalSince1970: seconds)
            )
        }
        let orders = [
            order("ready-new", .processed, 20, paid: true), order("preparing-old", .inProcess, 11),
            order("done", .delivered, 30), order("ready-old", .processed, 10),
            order("preparing-new", .inProcess, 21), order("canceled", .canceled, 40), order("open", .open, 50),
            Order(documentId: DocumentID(id: "empty", locationId: "42"), cart: [:], payments: [:],
                  statusLog: ["2026-04-01T12:00:00.000Z": "inProcess"], createdAt: Date(timeIntervalSince1970: 60)),
        ]
        let selected = KitchenOrders.select(from: orders)
        XCTAssertEqual(selected.map(\.documentId.id), ["preparing-new", "preparing-old", "ready-new", "ready-old"])
        XCTAssertEqual(selected.map(\.isPaid), [false, false, true, false])
        XCTAssertEqual(selected.first?.summary, ["Coffee \"冰\"": 5])
    }

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
