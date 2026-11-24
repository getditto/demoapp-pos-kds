import SwiftUI
import XCTest

final class KitchenBoardViewModelTests: XCTestCase {
    func testObservedOrderPartitionsPreserveOrderAndOnlyPartiallyEmptyWideBoardsUseWells() throws {
        let template = try OrderFixture.load()
        func order(_ id: String, _ status: OrderStatus) -> Order {
            Order(documentId: DocumentID(id: id, locationId: "A"), cart: template.cart,
                  payments: [:], statusLog: ["2026-11-12T12:00:00.000Z": status.rawValue], createdAt: template.createdAt)
        }
        let ready = order("ready-new", .processed)
        let preparing = order("preparing-new", .inProcess)
        let older = order("preparing-old", .inProcess)
        let observed = [ready, preparing, older]
        let phone = KitchenBoardViewModel(orders: observed, sizeClass: .compact)
        XCTAssertEqual(phone.phoneOrders.map(\.documentId.id), ["preparing-new", "preparing-old", "ready-new"])
        XCTAssertFalse(phone.showPreparingWell)
        XCTAssertFalse(phone.showReadyWell)

        let wide = KitchenBoardViewModel(orders: [ready], sizeClass: .regular)
        XCTAssertTrue(wide.showPreparingWell)
        XCTAssertFalse(wide.showReadyWell)
        let advanced = KitchenBoardViewModel(orders: [ready, preparing.appendingStatus(.processed)], sizeClass: .regular)
        XCTAssertEqual(advanced.ready.count, 2)
        XCTAssertTrue(advanced.showPreparingWell)
        let empty = KitchenBoardViewModel(orders: [], sizeClass: .regular)
        XCTAssertTrue(empty.isEmpty)
        XCTAssertFalse(empty.showPreparingWell)
        XCTAssertFalse(empty.showReadyWell)
    }
}
