import Combine
import DittoSwift
import XCTest

@MainActor final class StoreObserverTests: XCTestCase {
    private struct Item: Decodable, Sendable { let name: String }

    func testAdapterForwardsBoundQueryAndDecodesInitialAndSubsequentResults() async throws {
        try await TestDitto.withInstance { ditto in
            for (id, location, name) in [("one", "A", "Other location"), ("two", "B", "Initial")] {
                _ = try await ditto.store.execute(
                    query: "INSERT INTO observer_test DOCUMENTS (:item)",
                    arguments: ["item": ["_id": id, "locationId": location, "name": name]])
            }
            let initial = expectation(description: "Decoded initial payload")
            let updated = expectation(description: "Decoded updated payload")
            initial.assertForOverFulfill = false
            updated.assertForOverFulfill = false
            let subscription = ditto.store.observePublisher(
                query: "SELECT * FROM observer_test WHERE locationId = :locationId",
                arguments: ["locationId": "B"], mapTo: Item.self
            ).sink { items in
                    let names = items.map(\.name)
                    XCTAssertTrue(names == ["Initial"] || names == ["Updated"], "Unexpected decoded payload: \(names)")
                    if names == ["Initial"] { initial.fulfill() }
                    if names == ["Updated"] { updated.fulfill() }
                }
            defer { subscription.cancel() }
            await fulfillment(of: [initial], timeout: 5)
            _ = try await ditto.store.execute(
                query: "UPDATE observer_test SET name = :name WHERE _id = :id",
                arguments: ["name": "Updated", "id": "two"])
            await fulfillment(of: [updated], timeout: 5)
        }
    }
}
