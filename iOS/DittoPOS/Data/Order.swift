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
struct OrderItem: Identifiable, Codable {
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
        
        assert(parts.count == 2, "OrderItem id string initialization error. id: \(id)")

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
        case .inProcess: return Color("inProcessColor")
        case .processed: return Color("processedColor")
        case .delivered: return Color.black
        case .canceled: return Color.orange
        }
    }
}
//--------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------
// Order
//--------------------------------------------------------------------------------------------------
struct Order: Identifiable, Hashable {
    let _id: [String: String] //[id, locationId]
    let deviceId: String
    var saleItemIds = [String: String]() //[saleItemId, timestamp]
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

    static let collectionName = "orders"
}


// convenience replacement for string literal
// used mainly in accessing TTL value from config
let ordersKey = "orders"

extension Order {
    // centralized definition of hard-coded orders TTL
    // used as default value in AppConfig.Default
    static let defaultOrdersTTL = TimeInterval(60 * 60 * 24 * 7) // 7 days
}

extension Order: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.locationId == lhs.locationId
    }
}

// MARK: - Initializer
extension Order: DittoDecodable {
    init(value: [String : Any?]) {
        let statusInt = value["status"] as? Int
        var order = Order(
            _id: value["_id"] as! [String: String],
            deviceId: value["deviceId"] as! String,
            createdOn: DateFormatter.isoDate.date(from: value["createdOn"] as! String) ?? Date(),
            status: statusInt != nil ? OrderStatus(rawValue: statusInt!)! : .open
        )
        order.saleItemIds = value["saleItemIds"] as? [String: String] ?? [:]

        if let transactionIds = (value["transactionIds"] as? [String: Int]) {
            order.transactionIds = transactionIds.compactMapValues {
                TransactionStatus(rawValue: $0)
            }
        }

        self = order
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
}

extension Order {
    var orderItems: [OrderItem] {
        var items = [OrderItem]()
        for (compoundStringId, saleItemId) in saleItemIds {
            //NOTE: in this draft implementation we're relying on using the SaleItem demoItems
            // collection, where locationId is not relevant
            let draftSaleItemsArray = SaleItem.demoItems
            if let saleItem = draftSaleItemsArray.first( where: { $0.id == saleItemId } ) {
                let orderItem = OrderItem(id: compoundStringId, saleItem: saleItem)
                items.append(orderItem)
            }
        }
        return items.sorted(by: { $0.createdOn < $1.createdOn })
    }
    
    var total: Double {
        orderItems.sum(\.price.amount)
    }
}

typealias OrderItemsSummary = [String:Int]
extension Order {
    var summary: OrderItemsSummary {
        var items = OrderItemsSummary()
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

// MARK: - Query
extension Order {
    var selectByIDQuery: DittoQuery {
        (
            string: """
                SELECT * FROM COLLECTION \(Self.collectionName) (saleItemIds MAP, transactionIds MAP)
                WHERE _id = :_id
            """,
            args: [
                "_id": _id
            ]
        )
    }
    
    var insertNewQuery: DittoQuery {
        (
            string: """
                INSERT INTO COLLECTION \(Self.collectionName) (saleItemIds MAP, transactionIds MAP)
                DOCUMENTS (:new)
            """,
            args: [
                "new": [
                    "_id": _id,
                    "deviceId": deviceId,
                    "saleItemIds": saleItemIds,
                    "transactionIds": transactionIds,
                    "createdOn": DateFormatter.isoDate.string(from: createdOn),
                    "status": status
                ]
            ]
        )
    }

    func addItemQuery(orderItem: OrderItem) -> DittoQuery {
        (
            string: """
                UPDATE COLLECTION \(Self.collectionName) (saleItemIds MAP)
                SET
                    saleItemIds -> (
                        "\(orderItem.id)" = :itemID
                    ),
                    status = :status
                WHERE _id = :_id
            """,
            args: [
                "_id": _id,
                "itemID": orderItem.saleItem.id,
                "status": status.rawValue
            ]
        )
    }

    func updateStatusQuery(status: OrderStatus) -> DittoQuery {
        (
            string: """
                UPDATE \(Self.collectionName)
                SET status = :status
                WHERE _id = :_id
            """,
            args: [
                "_id": _id,
                "status": status.rawValue
            ]
        )
    }

    /*EVICTION: createdOn reset added for workaround when updating appconfig for testing
    // where current time is set for "older than" param, and where existing new/ready
    // order is evicted - UI becomes unresponsive.
    // COULD THIS HAPPEN IN REAL LIFE???
    var clearSaleItemIdsQuery: DittoQuery {
        (
            string: """
                UPDATE COLLECTION \(Self.collectionName) (saleItemIds MAP)
                SET
                    saleItemIds -> tombstone(),
                    status = :status
                WHERE _id = :_id
            """,
            args: [
                "_id": _id,
                "status": OrderStatus.open.rawValue
            ]
        )
    }
     */
    var resetQuery: DittoQuery {
        (
            string: """
                UPDATE COLLECTION \(Self.collectionName) (saleItemIds MAP)
                SET
                    saleItemIds -> tombstone(),
                    status = :status,
                    createdOn = :createdOn
                WHERE _id = :_id
            """,
            args: [
                "_id": _id,
                "status": OrderStatus.open.rawValue,
                "createdOn": DateFormatter.isoDate.string(from: Date())
            ]
        )
    }

    func addTransactionQuery(transaction: Transaction) -> DittoQuery {
        (
            string: """
                UPDATE COLLECTION \(Self.collectionName) (transactionIds MAP)
                SET
                    transactionIds -> (
                        "\(transaction.id)" = :status
                    )
                WHERE _id = :_id
            """,
            args: [
                "status": transaction.status.rawValue,
                "_id": _id
            ]
        )
    }

    static func ordersQuerySinceTTL(locId: String, ttl: TimeInterval) -> DittoQuery {
        (
            string: """
                SELECT * FROM COLLECTION \(Self.collectionName) (saleItemIds MAP, transactionIds MAP)
                WHERE _id.locationId = :locId
                AND createdOn > :TTL
            """,
            args: [
                "locId": locId,
                "TTL": DateFormatter.isoTimeFromNowString(-ttl)
            ]
        )
    }

    static var defaultLocationSyncQuery: DittoQuery {
        (
            string: """
                SELECT * FROM COLLECTION \(Self.collectionName) (saleItemIds MAP, transactionIds MAP)
                WHERE _id.locationId = :locationId
            """,
            args: ["locationId": Location.defaultLocation]
        )
    }

    static func incompleteOrderQuery(locationId: String, deviceId: String) -> DittoQuery {
        (
            string: """
                SELECT * FROM COLLECTION \(Self.collectionName) (saleItemIds MAP, transactionIds MAP)
                WHERE _id.locationId = :locationId
                    AND deviceId = :deviceId
                    AND transactionIds = :transIds
                ORDER BY createdOn ASC
            """,
            args: [
                "locationId": locationId,
                "deviceId": deviceId,
                "transIds": [String: Int]()
            ]
        )
    }
}

//--------------------------------------------------------------------------------------------------

extension Order {
    
    // Used by AppConfigView to construct wip config eviction query
    static func defaultEvictQueryStub() -> String {
        "EVICT FROM COLLECTION `orders` (saleItemIds MAP, transactionIds MAP) "
    }
    
    // Used by SyncService to log assumptions relating to orders subscription with TTL
    static func defaultOrdersSubQueryStub() -> String {
        "SELECT * FROM COLLECTION `orders` (saleItemIds MAP, transactionIds MAP) "
    }
}

// MARK: - Preview
extension Order {
    static func preview() -> Order {
        Order.new(locationId: "PreviewLocationId")
    }
}
