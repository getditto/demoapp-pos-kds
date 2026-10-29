import Combine
import DittoSwift
import XCTest
@testable import DittoPOS

@MainActor final class OrdersRepositoryTests: XCTestCase {
    func testAddOrderWritesToLocalStore() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let config = DittoConfig(
            databaseID: UUID().uuidString,
            connect: .smallPeersOnly(),
            persistenceDirectory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        try await exerciseOrderWrite(config: config)
    }

    private func exerciseOrderWrite(config: DittoConfig) async throws {
        let ditto = try Ditto.openSync(config: config)
        let repository = OrdersRepository(
            ditto: ditto,
            locationPublisher: Just<String?>(nil).eraseToAnyPublisher()
        )
        let timestamp = Date(timeIntervalSince1970: 1_775_044_800.123)
        let item = CartLineItem(saleItemId: "item-1", name: "Burger", imageName: "burger", price: Price(cents: 850), createdAt: timestamp)
        let order = Order.new(locationId: "42", createdAt: timestamp)
            .addingCartLineItem(item, lineItemId: "line-1")
        let delivered = expectation(description: "Order saved")
        let observer = try ditto.store.registerObserver(
            query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": order.documentId.id, "locationId": order.documentId.locationId],
            deliverOn: .main,
            handler: { result in
                let orders: [Order] = (try? result.decode()) ?? []
                guard let saved = orders.first else { return }
                XCTAssertEqual(saved, order)
                delivered.fulfill()
            }
        )
        defer { observer.cancel() }

        repository.add(order: order)
        await fulfillment(of: [delivered], timeout: 5)
    }
}
