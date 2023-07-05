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
    case open, inProcess, complete, delivered, canceled
}

struct Order: Identifiable, Hashable, Equatable {
    let _id: [String: String] // id, locationId
    var orderItems = [String: String]() //timestamp, menuItemId
    var transactionIds = [String: TransactionStatus]()
    let createdOn: Date
    var status: OrderStatus
    var id: String { _id["id"]! }
    var locationId: String { _id["locationId"]! }
    var createdOnStr: String { DateFormatter.isoDate.string(from: createdOn) }
    var title: String { String(id.prefix(8)) }
}

extension Order: Codable {}

extension Order {
    init(doc: DittoDocument) {
        self._id = doc["_id"].dictionaryValue as! [String: String]
        self.orderItems = doc["orderItems"]
            .dictionary as? [String: String] ?? [String: String]()
        self.transactionIds = doc["transactionIDs"]
            .dictionary as? [String: TransactionStatus] ?? [String: TransactionStatus]()
        self.createdOn = DateFormatter.isoDate
            .date(from: doc["createdOn"].stringValue) ?? Date()
        self.status = OrderStatus(rawValue: doc["status"].stringValue) ?? .open
    }
}

extension Order {
    func docDictionary() -> [String: Any?] {
        [
            "_id": _id,
            "orderItems": orderItems,
            "transactionIds": transactionIds,
            "createdOn": DateFormatter.isoDate.string(from: createdOn),
            "status": status
        ]
    }
}

extension Order {
    static func new(
        locationId: String,
        createdOn: Date = Date(),
        status: OrderStatus = .open
    ) -> Order {
        Order(_id: Self.makeId(locId: locationId), createdOn: createdOn, status: status)
    }
    
    static func makeId(locId: String) -> [String: String] {
        ["id": UUID().uuidString, "locationId": locId]
    }
}
