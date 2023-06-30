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
        self.loggingOption = DittoLogger.LoggingOptions(rawValue: DittoLogger.LoggingOptions.disabled.rawValue)!
        
        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID, token: Env.DITTO_PLAYGROUND_TOKEN
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
    @Published var allLocationsDocs = [DittoDocument]()
    private var allLocationsCancellable = AnyCancellable({})
    
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
    
    //    private var cancellables = Set<AnyCancellable>()
    
    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto
    
    private init() {
        self.locationsSubscription = ditto.store["locations"].findAll().subscribe()
        self.menuItemsSubscription = ditto.store["menuItems"].findAll().subscribe()
        self.ordersSubscription = ditto.store["orders"].findAll().subscribe()
        self.transactionsSubscription = ditto.store["transactions"].findAll().subscribe()
        
        updateAllLocationsPublisher()
    }
    
    func updateAllLocationsPublisher() {
        allLocationsCancellable = locationDocs
            .findAll()
            .liveQueryPublisher()
            .receive(on: DispatchQueue.main)
            .map { docs, _ in
                docs.map { $0 }
            }
            .assign(to: \.allLocationsDocs, on: self)
    }
    
    func locationPublisher(forId id: String) -> AnyPublisher<Location, Never> {
        locationDocs
            .findByID(id)
            .singleDocumentLiveQueryPublisher()
            .compactMap { doc, _ in return doc }
            .map { Location(doc: $0) }
            .eraseToAnyPublisher()
    }
    
    func orders(for loc: Location) -> [Order] {
        guard !loc.orderIds.isEmpty else { return [] }
        
        var orders = [Order]()
        for id in loc.orderIds.keys {
            if let doc = orderDocs
                .findByID(
                    DittoDocumentID(value: ["id": id, "locationId": loc.id] as [String : Any])
                ).exec() {
                let order = Order(doc: doc)
                orders.append(order)
            }
        }
        return orders.sorted(by: { $0.createdOn < $1.createdOn })
    }
    
    func addOrderToLocation(_ order: Order) {
        locationDocs.findByID(order.locationId).update { mutableDoc in
            mutableDoc?["orderIds"][order.id].set(order.createdOnStr)
        }
    }
    
    func addItemToOrder(item: MenuItem, _ order: Order) {
        
    }
    
    func orderDoc(for order: Order) -> DittoDocument? {
        orderDocs
            .findByID(
                DittoDocumentID(value: order._id)// as [String : Any])//["id": id, "locationId": loc.id] as [String : Any])
            ).exec()
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

