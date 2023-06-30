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
    let _id: [String: String] // id, locationId
    var menuItemIds = [String: Double]() //id, price
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
        self.menuItemIds = doc["menuItemIDs"]
            .dictionary as? [String: Double] ?? [String: Double]()
        self.transactionIds = doc["transactionIDs"]
            .dictionary as? [String: TransactionStatus] ?? [String: TransactionStatus]()
        self.createdOn = DateFormatter.isoDate
            .date(from: doc["createdOn"].stringValue) ?? Date()
        self.status = OrderStatus(rawValue: doc["status"].stringValue) ?? .incomplete
    }
}

extension Order {
    func docDictionary() -> [String: Any?] {
        [
            "_id": _id,
            "menuItemIds": menuItemIds,
            "transactionIds": transactionIds,
            "createdOn": DateFormatter.isoDate.string(from: createdOn),
            "status": status
        ]
    }
}



//extension Order {
//    static func new(
//        _id: [String: String],
////        locationId: String,
//        createdOn: Date = Date(),
//        status: OrderStatus = .incomplete
//    ) -> Order {
////        Order(id: id, locationId: locationId, createdOn: createdOn, status: status)
//        Order(_id: _id, createdOn: createdOn, status: status)
//    }
//}
extension Order {
    static func new(
        locationId: String,
        createdOn: Date = Date(),
        status: OrderStatus = .incomplete
    ) -> Order {
        Order(_id: Self._id(locId: locationId), createdOn: createdOn, status: status)
    }
    
    static func _id(locId: String) -> [String: String] {
        ["id": UUID().uuidString, "locationId": locId]
    }
}


// Convenience object to avoid unnecessary db lookups
//struct OrderItem: Identifiable, Hashable, Equatable {
//    let menuItem: MenuItem
//    var id: String { menuItem.id }
//    var title: String { menuItem.title }
//    var price: Double { menuItem.price }
//}
