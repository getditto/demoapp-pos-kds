///
//  Order.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation

enum OrderStatus: String, Codable {
    case incomplete, inProcess, complete, delivered, canceled
}

struct Order: Identifiable, Hashable, Equatable {
    let id: String
    let locationId: String
    var menuItemIds = [String: Double]() //id, price
    var transactionIds = [String: TransactionStatus]()
    let createdOn: Date
    var status: OrderStatus
}

extension Order {
    init(doc: DittoDocument) {
        self.id = doc["_id"].stringValue
        self.locationId = doc["locationID"].stringValue
        self.menuItemIds = doc["menuItemIDs"]
            .dictionary as? [String: Double] ?? [String: Double]()
        self.transactionIds = doc["transactionIDs"]
            .dictionary as? [String: TransactionStatus] ?? [String: TransactionStatus]()
        self.createdOn = DateFormatter.isoDate
            .date(from: doc["createdOn"].stringValue) ?? Date()
        self.status = OrderStatus(rawValue: doc["status"].stringValue) ?? .incomplete
    }
}

extension Order: Codable {}

extension Order {
    static func new(
        id: String = UUID().uuidString,
        locationId: String,
        createdOn: Date = Date(),
        status: OrderStatus = .incomplete
    ) -> Order {
        Order(id: id, locationId: locationId, createdOn: createdOn, status: status)
    }
}

// Convenience object to avoid unnecessary db lookups
//struct OrderItem: Identifiable, Hashable, Equatable {
//    let menuItem: MenuItem
//    var id: String { menuItem.id }
//    var title: String { menuItem.title }
//    var price: Double { menuItem.price }
//}
