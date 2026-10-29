import Combine
import DittoSwift
import XCTest
@testable import DittoPOS

// Main-actor isolated like the repositories: the observer delivers on the main
// queue, so registering and subscribing in one main-actor turn guarantees the
// subscriber is attached before the initial result arrives.
@MainActor final class StoreObserverTests: XCTestCase {
    private struct Item: Decodable {
        let name: String
    }

    func testPublisherFiltersDocumentsByLocation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let config = DittoConfig(
            databaseID: UUID().uuidString,
            connect: .smallPeersOnly(),
            persistenceDirectory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        try await exerciseLocationFilter(config: config)
    }

    private func exerciseLocationFilter(config: DittoConfig) async throws {
        let ditto = try Ditto.openSync(config: config)
        _ = try await ditto.store.execute(
            query: "INSERT INTO observer_test DOCUMENTS (:item)",
            arguments: ["item": ["_id": "one", "locationId": "A", "name": "First"]]
        )
        _ = try await ditto.store.execute(
            query: "INSERT INTO observer_test DOCUMENTS (:item)",
            arguments: ["item": ["_id": "two", "locationId": "B", "name": "Second"]]
        )

        let delivered = expectation(description: "Filtered items delivered")
        let subscription = ditto.store.observePublisher(
            query: "SELECT * FROM observer_test WHERE locationId = :locationId",
            arguments: ["locationId": "B"],
            mapTo: Item.self
        ).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion { XCTFail("Observer failed: \(error)") }
        }, receiveValue: { items in
            XCTAssertEqual(items.map(\.name), ["Second"])
            delivered.fulfill()
        })
        defer { subscription.cancel() }
        await fulfillment(of: [delivered], timeout: 5)
    }

    func testPublisherDeliversInsertedAndUpdatedDocuments() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let config = DittoConfig(
            databaseID: UUID().uuidString,
            connect: .smallPeersOnly(),
            persistenceDirectory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        try await exerciseObserver(config: config)
    }

    private func exerciseObserver(config: DittoConfig) async throws {
        let ditto = try Ditto.openSync(config: config)

        let inserted = expectation(description: "Inserted item delivered")
        let updated = expectation(description: "Updated item delivered")
        // The same result may be delivered more than once.
        inserted.assertForOverFulfill = false
        updated.assertForOverFulfill = false
        let subscription = ditto.store.observePublisher(
            query: "SELECT * FROM observer_test",
            mapTo: Item.self
        ).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion { XCTFail("Observer failed: \(error)") }
        }, receiveValue: { items in
            if items.first?.name == "First" { inserted.fulfill() }
            if items.first?.name == "Second" { updated.fulfill() }
        })
        defer { subscription.cancel() }

        _ = try await ditto.store.execute(
            query: "INSERT INTO observer_test DOCUMENTS (:item)",
            arguments: ["item": ["_id": "one", "name": "First"]]
        )
        await fulfillment(of: [inserted], timeout: 5)
        _ = try await ditto.store.execute(
            query: "UPDATE observer_test SET name = :name WHERE _id = :id",
            arguments: ["name": "Second", "id": "one"]
        )
        await fulfillment(of: [updated], timeout: 5)
    }
}
