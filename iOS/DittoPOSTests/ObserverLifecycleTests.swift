import Combine
import DittoSwift
import XCTest

@MainActor final class ObserverLifecycleTests: XCTestCase {
    private struct Item: Decodable, Sendable { let name: String }

    func testEachSubscriberDefersAndOwnsItsNativeObserver() async throws {
        try await TestDitto.withInstance { ditto in
            let baseline = ditto.store.observers.count
            let publisher = ditto.store.observePublisher(query: "SELECT * FROM lifecycle WHERE locationId = :locationId", arguments: ["locationId": "A"], mapTo: Item.self)
            XCTAssertEqual(ditto.store.observers.count, baseline)
            let first = publisher.sink { _ in }
            let firstObserver = try XCTUnwrap(ditto.store.observers.first { $0.queryString.contains("lifecycle") })
            XCTAssertEqual(ditto.store.observers.count, baseline + 1)
            first.cancel()
            XCTAssertTrue(firstObserver.isCancelled)
            XCTAssertEqual(ditto.store.observers.count, baseline)
            let second = publisher.sink { _ in }
            XCTAssertEqual(ditto.store.observers.count, baseline + 1)
            second.cancel()
            XCTAssertEqual(ditto.store.observers.count, baseline)

        }
    }

    func testVisibilityChangeDuringInitialDeliveryReleasesTheJustStartedObservation() {
        let session = VisibleObservation<String, Int>()
        let source = CurrentValueSubject<Int, Never>(1)
        var canceled = false
        session.set("A", observe: { _ in
            source.handleEvents(receiveCancel: { canceled = true }).eraseToAnyPublisher()
        }, receive: { _ in
            session.set(nil, observe: { _ in XCTFail("Hidden query started"); return source.eraseToAnyPublisher() }, receive: { _ in })
        })
        XCTAssertTrue(canceled)
    }
}
