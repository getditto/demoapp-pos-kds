///
//  Order.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

struct Order: Identifiable, Hashable, Codable {
    let _id: DocumentID
    var cart: [String: CartLineItem]
    var payments: [String: Payment]
    var statusLog: [String: String]      // iso-timestamp → OrderStatus.rawValue
    var createdOn: Date

    private enum CodingKeys: String, CodingKey {
        case _id, cart, payments, createdOn
        case statusLog = "status_log"
    }

    var id: String { _id.id }
    var locationId: String { _id.locationId }
    var title: String { String(id.prefix(8)) }

    var status: OrderStatus { StatusLogDerivation.currentStatus(from: statusLog) }

    var isPaid: Bool {
        status == .canceled || !payments.isEmpty
    }

    static let collectionName = "pos_orders"
}

// MARK: - Construction
extension Order {
    static func new(
        locationId: String,
        createdOn: Date = Date(),
        status: OrderStatus = .open
    ) -> Order {
        let entry = StatusLogDerivation.entry(status, at: createdOn)
        return Order(
            _id: DocumentID(id: UUID().uuidString, locationId: locationId),
            cart: [:],
            payments: [:],
            statusLog: [entry.key: entry.value],
            createdOn: createdOn
        )
    }
}

// MARK: - Mutation helpers
extension Order {
    func addingCartLineItem(_ lineItem: CartLineItem, lineItemId: String) -> Order {
        var copy = self
        copy.cart[lineItemId] = lineItem
        let entry = StatusLogDerivation.entry(.inProcess)
        copy.statusLog[entry.key] = entry.value
        return copy
    }

    func addingPayment(_ payment: Payment, paymentId: String) -> Order {
        var copy = self
        copy.payments[paymentId] = payment
        return copy
    }

    func appendingStatus(_ status: OrderStatus, at date: Date = Date()) -> Order {
        var copy = self
        let entry = StatusLogDerivation.entry(status, at: date)
        copy.statusLog[entry.key] = entry.value
        return copy
    }
}

// MARK: - Derived views
extension Order {
    var sortedLineItems: [CartLineItem] {
        cart.values.sorted { $0.createdOn < $1.createdOn }
    }

    var totalCents: Int {
        sortedLineItems.reduce(0) { $0 + $1.price.amount * $1.qty }
    }

    var total: Price { Price(cents: totalCents) }

    var summary: [String: Int] {
        var out: [String: Int] = [:]
        for line in sortedLineItems {
            out[line.name, default: 0] += line.qty
        }
        return out
    }
}

// MARK: - Queries
extension Order {
    var selectByIDQuery: DittoQuery {
        (
            string: """
                SELECT * FROM \(Self.collectionName)
                WHERE _id = deserialize_json(:_idJson)
            """,
            args: ["_idJson": _id.dittoJSONString()]
        )
    }

    /// Used for additive writes. Per-key removals stay surgical (UNSET).
    var upsertQuery: DittoQuery {
        (
            string: """
                INSERT INTO \(Self.collectionName)
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": dittoJSONString()]
        )
    }

    /// Nil when cart is already empty (no entries to UNSET).
    var clearCartQuery: DittoQuery? {
        guard !cart.isEmpty else { return nil }
        return (
            string: """
                UPDATE \(Self.collectionName)
                UNSET \(cartUnsetList)
                WHERE _id.id = :id AND _id.locationId = :locationId
            """,
            args: ["id": _id.id, "locationId": _id.locationId]
        )
    }

    var resetQuery: DittoQuery {
        let createdOnNow = DateFormatter.isoDate.string(from: Date())
        let baseArgs: [String: Any?] = [
            "id": _id.id,
            "locationId": _id.locationId,
            "createdOn": createdOnNow
        ]
        if cart.isEmpty {
            return (
                string: """
                    UPDATE \(Self.collectionName)
                    SET createdOn = :createdOn
                    WHERE _id.id = :id AND _id.locationId = :locationId
                """,
                args: baseArgs
            )
        }
        return (
            string: """
                UPDATE \(Self.collectionName)
                SET createdOn = :createdOn
                UNSET \(cartUnsetList)
                WHERE _id.id = :id AND _id.locationId = :locationId
            """,
            args: baseArgs
        )
    }

    private var cartUnsetList: String {
        cart.keys.map { "cart.\"\($0)\"" }.joined(separator: ", ")
    }

    static func ordersQuerySinceTTL(locationId: String) -> DittoQuery {
        (
            string: """
                SELECT * FROM \(Self.collectionName)
                WHERE _id.locationId = :locationId
                    AND createdOn > :TTL
            """,
            args: [
                "locationId": locationId,
                "TTL": DateFormatter.startOfTodayString
            ]
        )
    }

    static var evictionQuery: DittoQuery {
        (
            string: """
                EVICT FROM \(Self.collectionName)
                WHERE createdOn <= :TTL
            """,
            args: ["TTL": DateFormatter.startOfTodayString]
        )
    }

}

// MARK: - Preview
extension Order {
    static func preview() -> Order {
        Order.new(locationId: "PreviewLocationId")
    }
}
