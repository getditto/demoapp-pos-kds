//
//  StatusLog.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Order status modeled as a timestamp-keyed audit log instead of a single
// LWW field. Every transition is preserved (Ditto's add-wins map merge);
// the "current" status is *derived* at read time using "most-advanced state
// wins." A stale device coming online late and writing an older state cannot
// regress the order's status — the older entry stays in the log for
// auditability but the read-time derivation ignores it.
//
// See: https://docs.ditto.live/best-practices/conflict-resolution-patterns
enum OrderStatus: String, CaseIterable, Codable {
    case open
    case inProcess
    case processed
    case delivered
    case canceled

    // Higher = more advanced. `canceled` is terminal.
    var rank: Int {
        switch self {
        case .open: return 0
        case .inProcess: return 1
        case .processed: return 2
        case .delivered: return 3
        case .canceled: return 100  // terminal
        }
    }
}

enum StatusLogDerivation {
    static func currentStatus(from log: [String: String], default defaultStatus: OrderStatus = .open) -> OrderStatus {
        guard !log.isEmpty else { return defaultStatus }

        let entries: [(timestamp: String, status: OrderStatus)] = log.compactMap { ts, raw in
            guard let s = OrderStatus(rawValue: raw) else { return nil }
            return (ts, s)
        }
        guard !entries.isEmpty else { return defaultStatus }

        if entries.contains(where: { $0.status == .canceled }) {
            return .canceled
        }

        let maxRank = entries.map(\.status.rank).max()!
        let topTier = entries.filter { $0.status.rank == maxRank }
        let latest = topTier.max(by: { $0.timestamp < $1.timestamp })!
        return latest.status
    }

    static func entry(_ status: OrderStatus, at date: Date = Date()) -> (key: String, value: String) {
        (date.formatted(DittoDateFormatting.iso8601), status.rawValue)
    }
}
