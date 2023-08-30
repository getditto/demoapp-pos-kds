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
    let deviceId: String
    var saleItemIds = [String: String]() //timestamp, saleItemId
    var transactionIds = [String: TransactionStatus]() // transaction.id, transaction.status
    var createdOn: Date
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
        self.deviceId = doc["deviceId"].stringValue
        self.saleItemIds = doc["saleItemIds"].dictionaryValue as! [String: String]
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
            "deviceId": deviceId,
            "saleItemIds": saleItemIds,
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
        Order(
            _id: Self.newId(locId: locationId),
            deviceId: DittoService.shared.deviceId,
            createdOn: createdOn,
            status: status
        )
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

extension Order {
    var orderItems: [OrderItem] {
        var items = [OrderItem]()
        for (compoundStringId, saleItemId) in self.saleItemIds {
            //NOTE: in this draft implementation we're relying on using the SaleItem demoItems
            // collection, where locationId is not relevant
            let draftSaleItemsArray = SaleItem.demoItems
            if let saleItem = draftSaleItemsArray.first( where: { $0.id == saleItemId } ) {
                let orderItem = OrderItem(id: compoundStringId, saleItem: saleItem)
                items.append(orderItem)
            }
        }
//        return items.sorted(by: { $0.createdOn < $1.createdOn })
        return items
    }
    
    var total: Double {
        orderItems.sum(\.price.amount)
    }
}

extension Order {
    static func preview() -> Order {
        Order.new(locationId: "PreviewLocationId")
    }
}
