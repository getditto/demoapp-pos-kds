import Foundation
import XCTest

final class DittoWireDateTests: XCTestCase {
    private struct Fixtures: Decodable {
        struct Decoding: Decodable { let input: String; let canonical: String; let epochMillis: Int64 }
        struct Encoding: Decodable { let epochSeconds: Int64; let nanoseconds: Int; let canonical: String }
        let decoding: [Decoding]
        let encoding: [Encoding]
        let invalid: [String]
    }

    private func fixtures() throws -> Fixtures {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "wire-dates", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
    }

    func testSupportedInputsDecodeToUTCMilliseconds() throws {
        for example in try fixtures().decoding {
            let input = try JSONEncoder().encode(example.input)
            let date = try JSONDecoder.ditto.decode(Date.self, from: input)
            XCTAssertEqual(date.timeIntervalSince1970, Double(example.epochMillis) / 1000, accuracy: 0.000001, example.input)
            let output = try JSONEncoder.ditto.encode(date)
            XCTAssertEqual(try JSONDecoder().decode(String.self, from: output), example.canonical, example.input)
        }
    }

    func testEncodingTruncatesSubMillisecondsWithoutAdvancingTheSecond() throws {
        for example in try fixtures().encoding {
            let date = Date(timeIntervalSince1970: Double(example.epochSeconds) + Double(example.nanoseconds) / 1_000_000_000)
            let output = try JSONEncoder.ditto.encode(date)
            XCTAssertEqual(try JSONDecoder().decode(String.self, from: output), example.canonical)
        }
    }

    func testInvalidInputsAreRejected() throws {
        for input in try fixtures().invalid {
            XCTAssertThrowsError(try JSONDecoder.ditto.decode(Date.self, from: JSONEncoder().encode(input)), input)
        }
    }
}
