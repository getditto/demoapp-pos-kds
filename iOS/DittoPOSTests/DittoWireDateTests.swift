import Foundation
import XCTest
@testable import DittoPOS

final class DittoWireDateTests: XCTestCase {
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
}
