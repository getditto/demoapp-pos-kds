//
//  Order.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

struct Order: Hashable, Codable {
    let documentId: DocumentID
    var cart: [String: CartLineItem]
    var payments: [String: Payment]
    var statusLog: [String: String]      // iso-timestamp → OrderStatus.rawValue
    var createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case documentId = "_id"
        case cart, payments, createdAt
        case statusLog = "status_log"
    }

    var title: String { String(documentId.id.prefix(8)) }

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
        createdAt: Date = Date(),
        status: OrderStatus = .open
    ) -> Order {
        let entry = StatusLogDerivation.entry(status, at: createdAt)
        return Order(
            documentId: DocumentID(id: UUID().uuidString, locationId: locationId),
            cart: [:],
            payments: [:],
            statusLog: [entry.timestamp: entry.status],
            createdAt: createdAt
        )
    }
}

// MARK: - Mutation helpers
extension Order {
    func addingCartLineItem(_ lineItem: CartLineItem, lineItemId: String) -> Order {
        var copy = self
        copy.cart[lineItemId] = lineItem
        let entry = StatusLogDerivation.entry(.inProcess)
        copy.statusLog[entry.timestamp] = entry.status
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
        copy.statusLog[entry.timestamp] = entry.status
        return copy
    }
}

// MARK: - Derived views
extension Order {
    var sortedLineItems: [CartLineItem] {
        cart.values.sorted { $0.createdAt < $1.createdAt }
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

// MARK: - Preview
extension Order {
    static func preview() -> Order {
        Order.new(locationId: "PreviewLocationId")
    }
}
