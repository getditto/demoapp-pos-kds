///
//  DittoService.swift
//  DittoPOS
//
//  Created by Eric Turner on 2/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI

class DittoInstance: ObservableObject {
    @Published var loggingOption: DittoLogger.LoggingOptions
    private var cancellables = Set<AnyCancellable>()
    
    static var shared = DittoInstance()
    let ditto: Ditto

    private init() {
        self.loggingOption = DittoLogger.LoggingOptions(
            rawValue: DittoLogger.LoggingOptions.disabled.rawValue
        )!
        
        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN,
            enableDittoCloudSync: false // disabed for now for dev
        ))
        
        // Logging turned off for now to watch for dev UI logs
//        if let logOption = UserDefaults.standard.object(forKey: "dittoLoggingOption") as? Int {
//            self.loggingOption = DittoLogger.LoggingOptions(rawValue: logOption)!
//        } else {
//            self.loggingOption = DittoLogger.LoggingOptions(
//                rawValue: DittoLogger.LoggingOptions.debug.rawValue
//            )!
//        }
        
        // make sure our log level is set _before_ starting ditto.
        $loggingOption
            .sink {[weak self] option in
                UserDefaults.standard.set(option.rawValue, forKey: "dittoLoggingOption")
                self?.setupLogging(option)
            }
            .store(in: &cancellables)
        
        // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
        let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            try! ditto.startSync()
            
        }
    }

    func setupLogging(_ logOption: DittoLogger.LoggingOptions) {
        switch logOption {
        case .disabled:
            DittoLogger.enabled = false
        default:
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: logOption.rawValue)!
        }
    }
}

class DittoService: ObservableObject {
    @Published private(set) var allLocationDocs = [DittoDocument]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?// = ""
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)

    @Published private(set) var allOrderDocs = [DittoDocument]()
    private var allOrdersCancellable = AnyCancellable({})
    private let currentOrderSubject = CurrentValueSubject<Order?, Never>(nil)

    private var cancellables = Set<AnyCancellable>()
    
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
        
        $currentLocationId
            .sink {[weak self] locId in
                print("DS.currentLocationId changed to: \(locId ?? "NIL")")
                self?.updateAllLocations()
            }
            .store(in: &cancellables)

        updateAllLocations()
        
        $allLocationDocs
            .sink {[weak self] docs in
                print("DS.$allLocationDocs.sink: docs in count: \(docs.count)")
                if let locId = self?.currentLocationId,
                    let locDoc = docs.first(where: { $0.id == DittoDocumentID(value: locId) }) {
                    let loc = Location(doc: locDoc)
                    print("DS.$allLocationDocs.sink: FOUND Location doc for currentLocationId: \(loc.name)")
                    self?.currentLocationSubject.value = loc
                    
                    print("DS.$allLocationDocs.sink: SET currentOrder or NIL")
                    let locOrders = self?.orders(for: loc)
                    self?.currentOrderSubject.value = locOrders?.first
                }
            }
            .store(in: &cancellables)
        
        $allOrderDocs
            .sink {[weak self] docs in
                guard let doc = self?.currentOrderSubject.value else {
                    print("DS.$allOrderDocs.sink: no currentOrder --> return");
                    return
                }
                
                  if let dbDoc = docs.first(where: { $0.id == doc.docId() }) {
//                    print("DS.$allOrderDocs.sink: FOUND dbDoc: \(dbDoc)")
                    let updatedOrder = Order(doc: dbDoc)
//                      print("DS.$allOrderDocs.sink: SET updatedOrder: \(updatedOrder)")
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
    
    func addOrderToLocation(_ order: Order) {
        do {
            print("DS.\(#function): add Order(\(order.title)) to Orders collection")
            try orderDocs.upsert(order.docDictionary())
        } catch {
            print("DS.\(#function): FAIL TO ADD Order(\(order.title)) to Orders collection")
        }
        
        print("DS.\(#function): add Order \(order.title) to location: \(order.locationId)")
        locationDocs.findByID(order.locationId).update { [self] mutableDoc in
            mutableDoc?["orderIds"][order.id].set(order.createdOnStr)
            print("DS.\(#function): order(\(order.title)) added to mutableDoc.orderIds: \(mutableDoc!["orderIds"])")
            
            let loc = Location(doc: locationDocs.findByID(order.locationId).exec()!)
            print("DS.\(#function): CHECK for order added to loc: \(loc)")
        }
    }
    
    func addItemToOrder(item: OrderItem, order: Order) {
        orderDocs.findByID(order._id).update { mutableDoc in //[weak self] mutableDoc in
//            print("DS.\(#function): add (\(order.title)) to mutableDoc.orderItems)")
//            mutableDoc?["orderItems"][item.createdOnStr].set(item.menuItem.id) //[timestamp: menuItemId]
            
            print("DS.\(#function): UPDATE mutableDoc.orderItems: \(item.id))")
            mutableDoc?["orderItems"][item.id].set(item.menuItem.id) //[uuid_createdOn: menuItemId]
            mutableDoc?["status"].set(order.status.rawValue)
        }
    }
        
    func orders(for loc: Location) -> [Order] {
        guard !loc.orderIds.isEmpty else { return [] }
        
        var orders = [Order]()
        for id in loc.orderIds.keys {
                if let doc = orderDocForId(id, locId: loc.id) {
                let order = Order(doc: doc)
                orders.append(order)
            } else {
                print("DS.\(#function): WARNING - could not find OrderDoc for id: \(id)")
            }
        }
        return orders.sorted(by: { $0.createdOn > $1.createdOn })
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
                    print("DS.\(#function): add (\(transx.id)) to mutableDoc.transactionIds)")
                    mutableDoc?["transactionIds"][transx.id].set(transx.status.rawValue) //[id: status (Int)]
//                    mutableDoc?["status"].set(order.status.rawValue)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func updateCurrentOrder(_ fullId: DittoDocumentID) {
        if let doc = orderDocs.findByID(fullId).exec() {
            currentOrderSubject.value = Order(doc: doc)
        }
    }
}

/* Rae
for (id in order.payments.keys()) {
  let doc = ditto.store.collection("payments")
    .findById(DocumentID({
      "id": id,
      "locationId": 456,
      "orderId": "abc123"
    }).exec()
    paymentsForOrder.append(doc)
}
 */

