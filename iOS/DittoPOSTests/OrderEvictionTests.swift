import XCTest

@MainActor final class OrderEvictionTests: XCTestCase {
    func testElapsed24HoursGateAndSuccessfulCheckpoint() async throws {
        var date = Date(timeIntervalSince1970: 86_399)
        var last: TimeInterval = 0
        var cutoffs: [String] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let eviction = OrderEviction(
            now: { date }, calendar: calendar, lastRun: { last }, recordRun: { last = $0 },
            evict: { cutoffs.append($0) })
        let early = try await eviction.runIfDue()
        XCTAssertNil(early)
        XCTAssertTrue(cutoffs.isEmpty)
        date = Date(timeIntervalSince1970: 86_400)
        let due = try await eviction.runIfDue()
        XCTAssertEqual(due, "1970-01-02T00:00:00.000Z")
        XCTAssertEqual(last, 86_400)
        let repeated = try await eviction.runIfDue()
        XCTAssertNil(repeated)
        XCTAssertEqual(cutoffs.count, 1)
    }

    func testFailureDoesNotAdvanceCheckpointAndSameInvocationCanRetry() async throws {
        enum Failure: Error { case expected }
        let date = try DittoWireDate.date(from: "2026-11-02T04:30:00.000Z")
        var last: TimeInterval = 0
        var attempts = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let eviction = OrderEviction(
            now: { date }, calendar: calendar, lastRun: { last }, recordRun: { last = $0 },
            evict: { cutoff in
                attempts += 1
                XCTAssertEqual(cutoff, "2026-11-01T04:00:00.000Z")
                if attempts == 1 { throw Failure.expected }
            })
        do {
            _ = try await eviction.runIfDue()
            XCTFail("Expected injected storage failure")
        } catch Failure.expected {}
        XCTAssertEqual(last, 0)
        _ = try await eviction.runIfDue()
        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(last, date.timeIntervalSince1970)
    }
}
