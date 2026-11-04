//
//  StatusLogDerivationTests.swift
//  DittoPOSTests
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import XCTest

final class StatusLogDerivationTests: XCTestCase {

    func testEmptyOrUnknownLegacyLogUsesRequestedFallback() {
        for log in [[:], ["2026-04-01T00:00:00.000Z": "unknown-legacy-state"]] {
            XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .open)
            XCTAssertEqual(StatusLogDerivation.currentStatus(from: log, default: .inProcess), .inProcess)
        }
    }

    func testMostAdvancedRankWins() {
        let log = [
            "2026-04-01T00:00:00.000Z": "open",
            "2026-04-01T00:00:01.000Z": "inProcess",
            "2026-04-01T00:00:02.000Z": "processed"
        ]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .processed)
    }

    func testNewerLowerStatusCannotRegress() {
        let log = [
            "2026-04-01T00:00:00.500Z": "delivered",
            "2026-04-01T00:00:02.000Z": "open"
        ]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .delivered)
    }

    func testCanceledIsTerminal() {
        let log = [
            "2026-04-01T00:00:01.000Z": "canceled",
            "2026-04-01T00:00:02.000Z": "delivered"
        ]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .canceled)
    }

    func testEntryReturnsWireValueAndTimestamp() {
        let date = ISO8601DateFormatter().date(from: "2026-04-01T12:00:00Z")!
        let entry = StatusLogDerivation.entry(.processed, at: date)
        XCTAssertEqual(entry.status, "processed")
        XCTAssertEqual(entry.timestamp, "2026-04-01T12:00:00.000Z")
    }
}
