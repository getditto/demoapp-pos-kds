//
//  StatusLogDerivationTests.swift
//  DittoPOSTests
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import XCTest
@testable import DittoPOS

final class StatusLogDerivationTests: XCTestCase {

    func testEmptyLogReturnsDefault() {
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: [:]), .open)
    }

    func testDefaultOverrideHonoredWhenLogIsEmpty() {
        XCTAssertEqual(
            StatusLogDerivation.currentStatus(from: [:], default: .inProcess),
            .inProcess
        )
    }

    func testUnparseableEntriesAreIgnored() {
        let log = ["2026-04-01T00:00:00.000Z": "garbage"]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .open)
    }

    func testMostAdvancedRankWins() {
        let log = [
            "2026-04-01T00:00:00.000Z": "open",
            "2026-04-01T00:00:01.000Z": "inProcess",
            "2026-04-01T00:00:02.000Z": "processed"
        ]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .processed)
    }

    func testOlderWriteCannotRegress() {
        // Stale device coming online late writes an older OPEN entry —
        // older entry stays in the log for audit but does not regress.
        let log = [
            "2026-04-01T00:00:02.000Z": "delivered",
            "2026-04-01T00:00:00.500Z": "open"
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

    func testTieAtTopRankBreaksByLatestTimestamp() {
        let log = [
            "2026-04-01T00:00:01.000Z": "processed",
            "2026-04-01T00:00:02.000Z": "processed"
        ]
        XCTAssertEqual(StatusLogDerivation.currentStatus(from: log), .processed)
    }

    func testEntryReturnsWireValueAndTimestamp() {
        let date = ISO8601DateFormatter().date(from: "2026-04-01T12:00:00Z")!
        let entry = StatusLogDerivation.entry(.processed, at: date)
        XCTAssertEqual(entry.status, "processed")
        XCTAssertFalse(entry.timestamp.isEmpty)
    }
}
