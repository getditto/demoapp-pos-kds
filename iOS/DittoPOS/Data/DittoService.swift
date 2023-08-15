///
//  DittoService.swift
//  DittoPOS
//
//  Created by Eric Turner on 2/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoExportLogs
import DittoSwift
import SwiftUI

let defaultLoggingOption: DittoLogger.LoggingOptions = .error

class DittoService: ObservableObject {
    @Published var loggingOption: DittoLogger.LoggingOptions
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var allLocationDocs = [DittoDocument]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)
    
    @Published private(set) var allOrderDocs = [DittoDocument]()
    private var allOrdersCancellable = AnyCancellable({})

    @Published var currentOrderId: String?
    private let currentOrderSubject = CurrentValueSubject<Order?, Never>(nil)
    
    private var locationsSubscription: DittoSubscription
    private var menuItemsSubscription: DittoSubscription
    private var ordersSubscription: DittoSubscription
    private var transactionsSubscription: DittoSubscription

    var locationDocs: DittoCollection {
        ditto.store["locations"]
    }
    var menuItemDocs: DittoCollection {
        ditto.store["menuItems"]
    }
    var orderDocs: DittoCollection {
        ditto.store["orders"]
    }
    var transactionDocs: DittoCollection {
        ditto.store["transactions"]
    }
    
    func currentLocationPublisher() -> AnyPublisher<Location?, Never> {
        currentLocationSubject.eraseToAnyPublisher()
    }
    
    func currentOrderPublisher() -> AnyPublisher<Order?, Never> {
        currentOrderSubject.eraseToAnyPublisher()
    }
    
    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto
    
    private init() {
        self.locationsSubscription = ditto.store["locations"].findAll().subscribe()
        self.menuItemsSubscription = ditto.store["menuItems"].findAll().subscribe()
        self.ordersSubscription = ditto.store["orders"].findAll().subscribe()
        self.transactionsSubscription = ditto.store["transactions"].findAll().subscribe()
        
        // make sure our log level is set _before_ starting ditto.
        self.loggingOption = UserDefaults.standard.storedLoggingOption
        $loggingOption
            .sink {[weak self] option in
                UserDefaults.standard.storedLoggingOption = option
                self?.resetLogging()
            }
            .store(in: &cancellables)

        $currentLocationId
            .sink {[weak self] locId in
                self?.updateAllLocations()
            }
            .store(in: &cancellables)

        updateAllLocations()
                
        $allLocationDocs
            .sink {[weak self] docs in
                if let locId = self?.currentLocationId,
                    let locDoc = docs.first(where: { $0.id == DittoDocumentID(value: locId) }) {
                    let loc = Location(doc: locDoc)
                    self?.currentLocationSubject.value = loc
                }
            }
            .store(in: &cancellables)
        
        $currentOrderId
            .sink{[weak self] orderId in
                print("DS.currentOrderId changed to: \(orderId ?? "NIL")")
                if let id = orderId,
                   let loc = self?.currentLocationSubject.value,
                   let orderDoc = self?.orderDocForId(id, locId: loc.id) {
                    self?.currentOrderSubject.value = Order(doc: orderDoc)
                }
            }
            .store(in: &cancellables)
        
        $allOrderDocs
            .sink {[weak self] docs in
                print("\n\nCOUNT: DS.$allOrderDocs.sink: docs.count: \(docs.count)\n\n")
                guard let doc = self?.currentOrderSubject.value else {
                    print("DS.$allOrderDocs.sink: no currentOrder --> return");
                    return
                }
                                
                if let dbDoc = docs.first(where: { $0.id == doc.docId() }) {
                    let updatedOrder = Order(doc: dbDoc)
                    self?.currentOrderSubject.value = updatedOrder
                }
            }
            .store(in: &cancellables)
        
        updateAllOrders()
    }
    
    func updateAllLocations() {
        allLocationsCancellable = locationDocs
            .findAll()
            .liveQueryPublisher()
            .map { docs, _ in
                docs.map { $0 }
            }
            .assign(to: \.allLocationDocs, on: self)
    }
    
    func updateAllOrders() {
        allOrdersCancellable = orderDocs
            .findAll()
            .liveQueryPublisher()
            .map { docs, _ in
                docs.map { $0 }
            }
            .assign(to: \.allOrderDocs, on: self)
    }
    
    func addOrder(_ order: Order) {
        do {
            try orderDocs.upsert(order.docDictionary())
        } catch {
            print("DS.\(#function): FAIL TO ADD Order(\(order.title)) to Orders collection")
        }
    }
    
    func orderPublisher(_ order: Order) -> AnyPublisher<Order?, Never> {
        orderDocs.findByID(DittoDocumentID(value: order._id))
            .singleDocumentLiveQueryPublisher()
            .map {doc, _ in
                if let doc = doc {
                    return Order(doc: doc)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    func addItemToOrder(item: OrderItem, order: Order) {
        orderDocs.findByID(order._id).update { mutableDoc in
//            print("DS.\(#function): UPDATE mutableDoc.orderItems: \(item.id))")
            mutableDoc?["orderItems"][item.id].set(item.menuItem.id) //[uuid_createdOn: menuItemId]
            mutableDoc?["status"].set(order.status.rawValue)
        }
    }
        
    func orders(for loc: Location) -> [Order] {
        orderDocs.find("_id.locationId == '\(loc.id)'").exec()
            .map { Order(doc: $0) }
    }
    
    func orderDocForId(_ id: String, locId: String) -> DittoDocument? {
        orderDocs.findByID(DittoDocumentID(value: ["id": id, "locationId": locId])).exec()
    }
    
    func orderDoc(for order: Order) -> DittoDocument? {
        orderDocs.findByID(DittoDocumentID(value: order._id)).exec()
    }
    
    func updateOrder(_ order: Order, with transx: Transaction) {
        ditto.store.write { transaction in
            let transactions = transaction.scoped(toCollectionNamed: "transactions")
            let orders = transaction.scoped(toCollectionNamed: "orders")
            do {
                try transactions.upsert(transx.docDictionary())

                orders.findByID(order._id).update { mutableDoc in
//                    print("DS.\(#function): add (\(transx.id)) to mutableDoc.transactionIds)")
                    mutableDoc?["transactionIds"][transx.id].set(transx.status.rawValue) //[id: status (Int)]
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func clearCurrentOrderIems() {
        if let currOrder = currentOrderSubject.value {
            let open = OrderStatus(rawValue: OrderStatus.open.rawValue)
            orderDocs.findByID(DittoDocumentID(value: currOrder._id)).update { mutableDoc in
//                print("DS.\(#function): CLEAR CURRENT ORDER ITEMS")
                for id in currOrder.orderItems.keys {
                    mutableDoc?["orderItems"][id].remove()
                }
                mutableDoc?["status"].set(open)
            }
        }
    }
    
    // cancel order feature replaced by ^^ clearCurrrentOrderItems() to avoid accumulating many
    // empty orders. "Cancel" button action is now implemented as "Clear order items"
    func cancelCurrentOrder() {
        if let currOrder = currentOrderSubject.value {
            let canceled = OrderStatus(rawValue: OrderStatus.canceled.rawValue)
            orderDocs.findByID(currOrder._id).update { mutableDoc in
//                print("DS.\(#function): SET CURRENT ORDER STATUS CANCEL")
                mutableDoc?["status"].set(canceled)
            }
        }
    }
}
extension DittoService {
}

extension DittoService {
    fileprivate func resetLogging() {
        let logOption = UserDefaults.standard.storedLoggingOption
        switch logOption {
        case .disabled:
            DittoLogger.enabled = false
        default:
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: logOption.rawValue)!
            if let logFileURL = DittoLogManager.shared.logFileURL {
                DittoLogger.setLogFileURL(logFileURL)
            }
        }
    }
}

class DittoInstance {
    static var shared = DittoInstance()
    let ditto: Ditto

    private init() {
        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN
//            enableDittoCloudSync: false // disabled for now for dev
        ))
        
        // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
        let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            try! ditto.startSync()
        }
    }
}
