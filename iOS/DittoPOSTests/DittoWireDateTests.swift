import Foundation
import XCTest
@testable import DittoPOS

final class DittoWireDateTests: XCTestCase {
    private final class FailureCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0

        func increment() {
            lock.lock()
            defer { lock.unlock() }
            count += 1
        }

        func value() -> Int {
            lock.lock()
            defer { lock.unlock() }
            return count
        }
    }

    private struct Payload: Codable {
        let createdAt: Date
    }

    func testJSONUsesUTCAndMillisecondPrecision() throws {
        let examples = [
            ("2026-04-01T12:00:00.000Z", "2026-04-01T12:00:00.000Z"),
            ("2026-04-01T12:00:00.123Z", "2026-04-01T12:00:00.123Z"),
            ("2026-04-01T14:00:00.123+02:00", "2026-04-01T12:00:00.123Z")
        ]
        for (input, expected) in examples {
            let data = Data("{\"createdAt\":\"\(input)\"}".utf8)
            let payload = try JSONDecoder.ditto.decode(Payload.self, from: data)
            let encoded = try JSONEncoder.ditto.encode(payload)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: String])
            XCTAssertEqual(json["createdAt"], expected)
            XCTAssertEqual(try JSONDecoder.ditto.decode(Payload.self, from: encoded).createdAt, payload.createdAt)
        }
    }

    func testSubMillisecondDigitsAreTruncatedNotRounded() throws {
        let data = Data("{\"createdAt\":\"2026-04-01T23:59:59.9999Z\"}".utf8)
        let payload = try JSONDecoder.ditto.decode(Payload.self, from: data)
        let encoded = try JSONEncoder.ditto.encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: String])
        XCTAssertEqual(json["createdAt"], "2026-04-01T23:59:59.999Z")
    }

    func testInvalidTimestampIsRejected() {
        let data = Data("{\"createdAt\":\"invalid\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder.ditto.decode(Payload.self, from: data))
    }

    func testTimestampWithoutFractionalSecondsIsRejected() {
        let data = Data("{\"createdAt\":\"2026-04-01T12:00:00Z\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder.ditto.decode(Payload.self, from: data))
    }

    func testDateConversionWorksConcurrently() {
        let expected = "2026-04-01T12:00:00.123Z"
        let date = Date(timeIntervalSince1970: 1_775_044_800.123)
        let failures = FailureCounter()

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            let string = DittoWireDate.string(from: date)
            let decoded = try? DittoWireDate.date(from: string)
            if string != expected || decoded != date {
                failures.increment()
            }
        }

        XCTAssertEqual(failures.value(), 0)
    }
}
