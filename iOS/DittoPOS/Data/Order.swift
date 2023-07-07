///
//  Order.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation

//enum OrderStatus: String, Codable {
enum OrderStatus: Int, CaseIterable, Codable {
    // "processed" means order is processed by kitchen, ready for delivery
    case open = 0, inProcess, processed, delivered, canceled
    
    var title: String {
        switch self {
        case .open: return "open"
        case .inProcess: return "inProcess"
        case .processed: return "processed"
        case .delivered: return "delivered"
        case .canceled: return "canceled"
        }
    }
}

struct Order: Identifiable, Hashable, Equatable {
    let _id: [String: String] // id, locationId
    var orderItems = [String: String]() //timestamp, menuItemId
    var transactionIds = [String: TransactionStatus]() // transaction.id, transaction.status
    let createdOn: Date
    var status: OrderStatus
    
    var id: String { _id["id"]! }
    var locationId: String { _id["locationId"]! }
    var createdOnStr: String { DateFormatter.isoDate.string(from: createdOn) }
    var title: String { String(id.prefix(8)) }
    var isPaid: Bool {
        // assume canceled and non-empty transactions means paid and therefore final
        // N.B. this does not consider refunds or failed transactions
        (status == .canceled) || transactionIds.isEmpty == false
    }
}

extension Order: Codable {}

extension Order {
    init(doc: DittoDocument) {
        self._id = doc["_id"].dictionaryValue as! [String: String]
        self.orderItems = doc["orderItems"]
            .dictionaryValue as! [String: String]
        self.transactionIds = Transaction.statusDict(
            doc["transactionIds"].dictionaryValue as! [String: Int]
        )
        self.createdOn = DateFormatter.isoDate
            .date(from: doc["createdOn"].stringValue) ?? Date()
        self.status = OrderStatus(rawValue: doc["status"].intValue) ?? .open
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
        Order(_id: Self.newId(locId: locationId), createdOn: createdOn, status: status)
    }
    
    static func newId(locId: String) -> [String: String] {
        ["id": UUID().uuidString, "locationId": locId]
    }
    
    func docId() -> DittoDocumentID {
        DittoDocumentID(value: self._id)
    }
    
    static func docId(_ orderId: String, _ locId: String) -> DittoDocumentID {
        DittoDocumentID(value: ["id": orderId, "locationId": locId])
    }
}
