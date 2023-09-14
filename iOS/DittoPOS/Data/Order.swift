///
//  Order.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

//--------------------------------------------------------------------------------------------------
// OrderItem
//--------------------------------------------------------------------------------------------------
/// A UI model object, not used with ditto, with unique ID, representing a saleItem
struct OrderItem: Identifiable {
    let id: String
    let saleItem: SaleItem
    var price: Price { saleItem.price }
    var title: String { saleItem.title }
    let createdOnStr: String
    let createdOn: Date
}

extension OrderItem {
    // for initializing from Order.saleItemIds keys
    init(id: String, saleItem: SaleItem) { // initialized with string format as "uuid_timestamp"
        let parts = id.split(separator: "_")
        
        assert(parts.count == 2, "OrderItem id string initialization error")
        
        self.id = String(parts[0])
        self.createdOnStr = String(parts[1])
        self.createdOn = DateFormatter.isoDate.date(from: createdOnStr)!
        self.saleItem = saleItem
    }
    
    // for initializing new orderItem object with a saleItem selected from POS
    init(saleItem: SaleItem) {
        self.createdOn = Date()
        self.createdOnStr = DateFormatter.isoDate.string(from: createdOn)
        self.id = "\(UUID().uuidString)_\(createdOnStr)"
        self.saleItem = saleItem
    }
}

extension OrderItem: Equatable, Hashable {
    static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        lhs.saleItem == rhs.saleItem
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(saleItem)
    }
}
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// OrderStatus
//--------------------------------------------------------------------------------------------------
enum OrderStatus: Int, CaseIterable, Codable {
    // "processed" means order is processed (e.g. by kitchen), ready for delivery
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
    
    var color: Color {
        switch self {
        case .open: return Color.gray
        case .inProcess: return Color.blue
        case .processed: return Color.green
        case .delivered: return Color.black
        case .canceled: return Color.orange
        }
    }
}
//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------
// Order
//--------------------------------------------------------------------------------------------------
struct Order: Identifiable, Hashable, Equatable {
    let _id: [String: String] // id, locationId
    let deviceId: String
    var saleItemIds = [String: String]() //timestamp, saleItemId
    var transactionIds = [String: TransactionStatus]() // transaction.id, transaction.status
    var orderItems = [OrderItem]()
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
        self.orderItems = getOrderItems()
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
            "status": status //should this be .rawValue?
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
    func getOrderItems() -> [OrderItem] {
        var items = [OrderItem]()
        for (compoundStringId, saleItemId) in self.saleItemIds {
            //NOTE: in this draft implementation we're relying on using the SaleItem demoItems
            // collection, where locationId is not relevant
            let draftSaleItemsArray = SaleItem.demoItems
            if let saleItem = draftSaleItemsArray.first( where: { $0.id == saleItemId } ) {
                let orderItem = OrderItem(id: compoundStringId, saleItem: saleItem)
//                print("Order.getOrderItems(): append orderItem: \(orderItem.saleItem.title)")
                items.append(orderItem)
            }
        }
//        print("Order.getOrderItems(): return \(items.count)")
        return items.sorted(by: { $0.createdOn < $1.createdOn })
    }
    
    var total: Double {
        orderItems.sum(\.price.amount)
    }
}

extension Order {
    static func isPaid(_ doc: DittoDocument) -> Bool {
        doc["transactionIds"].dictionaryValue.count > 0
    }
}

typealias OrderItemsSummary = [String:Int]
extension Order {
    var summary: OrderItemsSummary {
        var items = OrderItemsSummary()
        let orderItems = getOrderItems()
        for item in orderItems {
            if let val = items.updateValue(1, forKey: item.title) {
                items[item.title] = val + 1
            } else {
                items.updateValue(1, forKey: item.title)
            }
        }
        return items
    }
}
//--------------------------------------------------------------------------------------------------



extension Order {
    static func preview() -> Order {
        Order.new(locationId: "PreviewLocationId")
    }
}
