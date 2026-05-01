//
//  StatusLog.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Order status as a timestamp-keyed audit log. Current value is derived at
// read time via "most-advanced state wins" — stale writes never regress.
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
        (DateFormatter.isoDate.string(from: date), status.rawValue)
    }
}
