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

/*
 TRUE:
     - enables the Locations tab view
     - requires user selection from default collection of demo locations listed in Locations tab
     - allows switching between locations at runtime, e.g. to see orders from different locations
       in KDS view
 FALSE:
    - enables Profile form view at first launch; hides Locations tab
    - requires user to create location from form view company and location name values
    - KDS view displays only orders for location created from profile
 
 Note: in both cases, the (latest selected) locationId is persisted in UserDefaults and
       this location is used at launch
 */
let USE_DEFAULT_LOCATIONS = false

// Displays gear icon for DittoSwiftTools SettingsView
let ENABLE_SETTINGS_VIEW = true

let defaultLoggingOption: DittoLogger.LoggingOptions = .error

// Used to constrain orders subscriptions to 1 day old or newer
let OrderTTL: TimeInterval = 60 * 60 * 24 //24hrs

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
        
        // use case: user-defined location
        // ProfileScreen creates User from form input and saves to UserDefaults, triggering here
        UserDefaults.standard.userDataPublisher.sink { [weak self] jsonData in
            guard let self = self, let data = jsonData else { return }
            guard let user = JSONDecoder.objectFromData(data) as User? else {
                print("DS.userDataPublisher.sink: User from jsonData FAILED --> RETURN")
                return
            }
            
            let loc = Location(id: user.locationId, name: user.locationName)
            do {
                try locationDocs.upsert( loc.docDictionary() )
            } catch {
                print("DS.\(#function): FAIL UPSERT LOCATION \(loc.id)")
            }
            
            // setting here will save locId and update subscriptions
            currentLocationId = loc.id
        }
        .store(in: &cancellables)
        
        if USE_DEFAULT_LOCATIONS {
            setupDemoLocationDocs()
        }
        
        updateLocationsPublisher()

        $currentLocationId
            .sink {[weak self] locId in
                guard let locId = locId, let self = self else { return }
                saveLocationId(locId)
                // reset subscription for new location
                ordersSubscription.cancel()
                ordersSubscription = orderDocs.find(ordersQuerySinceTTL(locId: locId)).subscribe()
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
    
    // use case: user-defined location
    // the save to UserDefaults will trigger the userData publisher sink (above)
    func saveUser(company: String, location: String) {
        let user = User(companyName: company, locationName: location)
        guard let jsonData = JSONEncoder.encodedObject(user) else {
            print("DS.\(#function): jsonData from user FAILED --> RETURN")
            return
        }
        UserDefaults.standard.userData = jsonData
    }
    
    func updateLocationsPublisher() {
        if USE_DEFAULT_LOCATIONS {
            allLocationsCancellable = locationDocs
                .findAll()
                .liveQueryPublisher()
                .map { docs, _ in
                    return docs.map { $0 }
                        .filter { Location.demoLocationsIds.contains($0.id.toString()) }
                }
                .assign(to: \.allLocationDocs, on: self)
        } else {
            allLocationsCancellable = locationDocs
                .findAll()
                .liveQueryPublisher()
                .map { docs, _ in
                    return docs.map { $0 }
                }
                .assign(to: \.allLocationDocs, on: self)
        }
    }
    
    func updateOrdersPublisher(_ locId: String) {
        allOrdersCancellable = orderDocs
            .find(ordersSubscription.query)
            .liveQueryPublisher()
            .map { docs, _ in
                return docs.map { $0 }
            }
            .assign(to: \.locationOrderDocs, on: self)
    }
        
    func ordersQuerySinceTTL(locId: String) -> String {
        "_id.locationId == '\(locId)' && " +
        "createdOn > '\(DateFormatter.isoTimeFromNowString(-OrderTTL))'"
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
            try orderDocs.upsert(order.docDictionary())
        } catch {
            print("DS.\(#function): FAIL TO ADD Order(\(order.title)) to Orders collection")
        }
    }

    func addItemToOrder(item: OrderItem, order: Order) {
        orderDocs.findByID(order._id).update { mutableDoc in
            mutableDoc?["saleItemIds"][item.id].set(item.saleItem.id) //[uuid_createdOn: saleItemId]
            mutableDoc?["status"].set(order.status.rawValue)
        }
    }
    
    func updateOrderStatus(_ order: Order, with status: OrderStatus) {
        orderDocs.findByID(order._id).update { mutableDoc in
            mutableDoc?["status"].set(status.rawValue)
        }
    }

    func updateOrderTransaction(_ order: Order, with transx: Transaction) {
        ditto.store.write { transaction in
            let transactions = transaction.scoped(toCollectionNamed: "transactions")
            let orders = transaction.scoped(toCollectionNamed: "orders")
            do {
                try transactions.upsert(transx.docDictionary())

                orders.findByID(order._id).update { mutableDoc in
                    mutableDoc?["transactionIds"][transx.id].set(transx.status.rawValue) //[id: status (Int)]                    
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func clearOrderSaleItemIds(_ order: Order) {
        orderDocs.findByID(DittoDocumentID(value: order._id)).update { mutableDoc in
            for id in order.saleItemIds.keys {
                mutableDoc?["saleItemIds"][id].remove()
            }
            let open = OrderStatus(rawValue: OrderStatus.open.rawValue)
            mutableDoc?["status"].set(open)
        }
    }
    
    func restoredIncompleteOrder(for locId: String?) -> Order? {
        guard let locId = locId ?? UserDefaults.standard.storedLocationId else {
            return nil
        }
        
        let incompleteOrderDocs = orderDocs.find(
            "_id.locationId == '\(locId)'" +
            " && createdOn > '\(DateFormatter.isoTimeFromNowString(-OrderTTL))'" +
            " && deviceId == '\(deviceId)'" +
            " && length(keys(transactionIds)) == 0"
        ).exec().sorted(by: { $0["createdOn"].stringValue < $1["createdOn"].stringValue })
        
        // Reset as new
        if let doc = incompleteOrderDocs.first {
            print("DS.\(#function): FOUND INCOMPLETE ORDER TO RECYCLE")
            var order = Order(doc: doc)
            
            resetOrderDoc(for: order)

            // The returned Order object is only to immediately update the UI by the caller;
            // a new Order object will be created with the values mutated in resetOrderDoc()
            // when the liveQuery/Publisher is fired by the update
            order.createdOn = Date()
            order.saleItemIds.removeAll()
            order.orderItems = []
            order.status = OrderStatus.open
            return order
        }
        
        return nil
    }
    
    func resetOrderDoc(for order: Order) {
        orderDocs.findByID(order.docId()).update { mutableDoc in
            print("DS.\(#function): RESET ORDER \(order.title)")
            
            for id in order.saleItemIds.keys {
                mutableDoc?["saleItemIds"][id].remove()
            }
            
            let open = OrderStatus(rawValue: OrderStatus.open.rawValue)
            mutableDoc?["status"].set(open)
            
            // Reset createdOn to now
            let newDateStr = DateFormatter.isoDate.string(from: Date())
            mutableDoc?["createdOn"].set(newDateStr)
        }
    }
    
    func updateOrderCreatedDate(_ order: Order, date: Date = Date()) {
        orderDocs.findByID(order.id).update {mutableDoc in
            let newDateStr = DateFormatter.isoDate.string(from: date)
            mutableDoc?["createdOn"].set(newDateStr)
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
        // Assign new directory in order to avoide conflict with the old SkyService version.
        let persistenceDirURL = try? FileManager()
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto-pos-demo")

        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN,
            enableDittoCloudSync: true
        ), persistenceDirectory: persistenceDirURL)
    }
}
