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
    @Published var currentLocation: Location?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)
    
    @Published private(set) var locationOrderDocs = [DittoDocument]()
    private var allOrdersCancellable = AnyCancellable({})
    
    var deviceId: String //ditto.siteID as String to partition ordering to devices
    
    private var locationsSubscription: DittoSubscription
    private var ordersSubscription: DittoSubscription
    private var transactionsSubscription: DittoSubscription

    var locationDocs: DittoCollection {
        ditto.store["locations"]
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
    
    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto
    
    private init() {
        self.locationsSubscription = ditto.store["locations"].findAll().subscribe()
        //initial subscription query will find zero matches
        self.ordersSubscription = ditto.store["orders"].find("_id.locationId == '00000'").subscribe()
        self.transactionsSubscription = ditto.store["transactions"].findAll().subscribe()
        self.deviceId = String(ditto.siteID)
        
        // make sure our log level is set _before_ starting ditto.
        self.loggingOption = UserDefaults.standard.storedLoggingOption
        $loggingOption
            .sink {[weak self] option in
                UserDefaults.standard.storedLoggingOption = option
                self?.resetLogging()
            }
            .store(in: &cancellables)
        
        
        // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
        let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            try! ditto.startSync()
        }
        
        setupDemoLocationDocs()
        updateLocationsPublisher()

        $currentLocationId
            .sink {[weak self] locId in
                guard let locId = locId else {
//                    print("DS.$currentLocationId.sink: value in is NIL --> return")
                    return
                }
                guard let self = self else { return }
                saveLocationId(locId)

                ordersSubscription.cancel()
                ordersSubscription = orderDocs.find(ordersQuerySinceYesterday(locId: locId)).subscribe()
                updateOrdersPublisher(locId)
                updateCurrentLocation(locId)
            }
            .store(in: &cancellables)
        
        self.currentLocationId = self.storedLocationId()
        if let locId = currentLocationId {
            updateOrdersPublisher(locId)
            updateCurrentLocation(locId)
        }
    }
    
    func updateLocationsPublisher() {
        allLocationsCancellable = locationDocs
            .findAll()
            .liveQueryPublisher()
            .map { docs, _ in
                return docs.map { $0 }
            }
            .assign(to: \.allLocationDocs, on: self)
    }
    
    func updateOrdersPublisher(_ locId: String) {
        print("DS.\(#function) --> in")
        allOrdersCancellable = orderDocs
            .find(ordersSubscription.query)
            .liveQueryPublisher()
            .map { docs, _ in
//                print("DS.\(#function): locationOrderDocs publisher fired with count: \(docs.count)")
                return docs.map { $0 }
            }
            .assign(to: \.locationOrderDocs, on: self)
    }
        
    func ordersQuerySinceYesterday(locId: String) -> String {
        "_id.locationId == '\(locId)' && " +
        "createdOn > '\(DateFormatter.iso24HoursAgoString)'"
    }
    
    func orderPublisher(_ order: Order) -> AnyPublisher<Order, Never> {
        orderDocs.findByID(DittoDocumentID(value: order._id))
            .singleDocumentLiveQueryPublisher()
            .compactMap {doc, _ in
                if let doc = doc {
                    return Order(doc: doc)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
    
    func addOrder(_ order: Order) {
        do {
//            print("DS.\(#function): try add order: \(order.id)")
            try orderDocs.upsert(order.docDictionary())
        } catch {
            print("DS.\(#function): FAIL TO ADD Order(\(order.title)) to Orders collection")
        }
    }

    func addItemToOrder(item: OrderItem, order: Order) {
        orderDocs.findByID(order._id).update { mutableDoc in
//            print("DS.\(#function): UPDATE mutableDoc.saleItemIds: \(item.id))")
            mutableDoc?["saleItemIds"][item.id].set(item.saleItem.id) //[uuid_createdOn: saleItemId]
            mutableDoc?["status"].set(order.status.rawValue)
        }
    }
    
    func updateOrderStatus(_ order: Order, with status: OrderStatus) {
        orderDocs.findByID(order._id).update { mutableDoc in
//            let oldStatus = OrderStatus(rawValue: mutableDoc!["status"].intValue)!
//            print("DS.\(#function): try UPDATE mutableDoc.status from \(oldStatus.title) to \(status.title)")

            mutableDoc?["status"].set(status.rawValue)

//            let newStatus = OrderStatus(rawValue: mutableDoc!["status"].intValue)!
//            print("DS.\(#function): mutableDoc.status UPDATED to \(newStatus.title)")
        }
    }

    func updateOrderTransaction(_ order: Order, with transx: Transaction) {
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
    
    func clearOrderSaleItemIds(_ order: Order) {
        orderDocs.findByID(DittoDocumentID(value: order._id)).update { mutableDoc in
//                print("DS.\(#function): CLEAR ORDER ITEMS")
            for id in order.saleItemIds.keys {
                mutableDoc?["saleItemIds"][id].remove()
            }
            let open = OrderStatus(rawValue: OrderStatus.open.rawValue)
            mutableDoc?["status"].set(open)
        }
    }
}

extension DittoService {
    func setupDemoLocationDocs() {
        for loc in Location.demoLocations {
            try! locationDocs.upsert(
                loc.docDictionary(),
                writeStrategy: .insertDefaultIfAbsent
            )
        }
    }
    
    func updateCurrentLocation(_ locId: String?) {
        guard let locId = locId else { return }
        if let locDoc = locationDocs.findByID(DittoDocumentID(value: locId)).exec() {
            let loc = Location(doc: locDoc)
            currentLocation = loc
            currentLocationSubject.value = loc
        }
    }
}

extension DittoService {
    func storedLocationId() -> String? {
        UserDefaults.standard.storedLocationId
    }
    func saveLocationId(_ newId: String) {
        UserDefaults.standard.storedLocationId = newId
    }
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
    }
}
