///
//  DittoService.swift
//  DittoPOS
//
//  Created by Eric Turner on 2/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoExportLogs
import DittoHeartbeat
import DittoSwift
import SwiftUI

// MARK: - DittoInstance
final class DittoInstance: ObservableObject {
    
    static var shared = DittoInstance()
    let ditto: Ditto

    private init() {
        // Assign new directory to avoid conflict with the old SkyService version.
        #if os(tvOS)
        let directory: FileManager.SearchPathDirectory = .cachesDirectory
        #else
        let directory: FileManager.SearchPathDirectory = .documentDirectory
        #endif

        let persistenceDirURL = try? FileManager()
            .url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto-pos-demo")

        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN,
            enableDittoCloudSync: false
        ), persistenceDirectory: persistenceDirURL)
        
        ditto.updateTransportConfig { transportConfig in
            // Set the Ditto Websocket URL
            transportConfig.connect.webSocketURLs.insert(Env.DITTO_WEBSOCKET_URL)
        }
        
        do {
            // Disable sync with V3 Ditto
            try ditto.disableSyncWithV3()
        } catch let error {
            print("ERROR: disableSyncWithV3() failed with error \"\(error)\"")
        }
        
        Task {
            do {
                // disable strict mode - allows for DQL with counters and objects as CRDT maps, must be called before startSync
                // https://docs.ditto.live/dql/strict-mode
                try await ditto.store.execute(query: "ALTER SYSTEM SET DQL_STRICT_MODE = false")
                
                // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
                let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                if !isPreview {
                    try ditto.startSync()
                }
            } catch let error {
                print("ERROR: Setting DQL_STRICT_MODE or starting sync failed with error \"\(error)\"")
            }
        }
    }
}

// Used to constrain orders subscriptions to 1 day old or newer
let OrderTTL: TimeInterval = 60 * 60 * 24 //24hrs

@MainActor class DittoService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var allLocations = [Location]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?
    @Published private(set) var currentLocation: Location?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)

    @Published private(set) var locationOrders = [Order]()
    private var allOrdersCancellable = AnyCancellable({})
    
    //ditto.siteID as String to partition ordering to devices
    private(set) var deviceId: String

    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto

    // Heartbeat
    var heartbeatConfig: DittoHeartbeatConfig?
    var heartbeatCallback: HeartbeatCallback = {_ in}
    private var heartbeatVM: HeartbeatVM

    private let storeService: StoreService
    private let syncService: SyncService

    private init() {
        storeService = StoreService(ditto.store)
        syncService = SyncService(ditto.sync)
        syncService.registerInitialSubscriptions()

        deviceId = String(ditto.siteID)

        heartbeatVM = HeartbeatVM(ditto: ditto)
        
        updateLocationsPublisher()

        currentLocationId = Settings.locationId
        
        $currentLocationId
            .combineLatest($allLocations)
            .sink {[weak self] locId, allLocations in
                guard let locId = locId, let self = self else { return }
                
                if locId != Settings.locationId {
                    Settings.locationId = locId
                }

                if Settings.useDemoLocations {
                    storeService.setupDemoLocations()
                }

                // reset subscription for new location
                syncService.cancelOrdersSubscription()
                syncService.registerOrdersSinceTTLSubscription(locId: locId)

                updateOrdersPublisher(locId)
                Task {
                    await MainActor.run {[weak self] in
                        self?.updateCurrentLocation(locId)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // use case: store user-defined location
    func saveCustomLocation(company: String, location: String) {
        let loc = CustomLocation(companyName: company, locationName: location)
        guard let jsonData = JSONEncoder.encodedObject(loc) else {
            print("DS.\(#function): jsonData from custom location FAILED --> RETURN")
            return
        }

        Settings.customLocation = jsonData
        
        storeService.insertLocation(of: loc)

        // setting here will save locationId and update subscriptions in sink above
        currentLocationId = loc.locationId
        
        do {
            // add locationId to small_peer_info metadata
            try ditto.smallPeerInfo.setMetadata(["locationId": loc.locationId])
        } catch {
            print("DS.smallPeerInfo.metadata: Error \(error)")
        }
    }

    func orderPublisher(_ order: Order) -> AnyPublisher<Order, Never> {
        storeService.selectByIDObservePublisher(order)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    func add(order: Order) {
        storeService.insert(order: order)
    }

    func add(item: OrderItem, to order: Order) {
        storeService.add(item: item, to: order)
    }

    func updateStatus(of order: Order, with status: OrderStatus) {
        storeService.updateStatus(of: order, with: status)
    }

    func clearSaleItemIds(of order: Order) {
        storeService.clearSaleItemIds(of: order)
    }

    func reset(order: Order) {
        storeService.reset(order: order)
    }

    func updateOrderTransaction(_ order: Order, with transx: Transaction) {
        // NOTE: DQL v1 (4.5.x) doesn't support write transactions, so these
        // are written to the store asynchronously for now.
        storeService.insert(transaction: transx)
        storeService.add(transx, to: order)
    }

    func incompleteOrderFuture(locationId: String? = nil, device: String? = nil) -> Future<Order?, Never> {
        guard let locId = locationId ?? currentLocationId else {
            return Future { promise in  promise(.success(nil)) }
        }
        return storeService.incompleteOrderFuture(locationId: locId, deviceId: device ?? deviceId)
    }

    //MARK: - Heartbeat Tool
    func startHeartbeat() {
        guard let heartbeatConfig = heartbeatConfig else {
            print("Heartbeat Tool not Configured")
            return
        }

        if self.heartbeatVM.isEnabled {
            self.stopHeartbeat()
        }
        self.heartbeatVM.startHeartbeat(config: heartbeatConfig, callback: heartbeatCallback)
    }

    func stopHeartbeat() {
        self.heartbeatVM.stopHeartbeat()
    }
}

extension DittoService {
    enum LocationsSetupOption { case demo, custom }
    
    var locationSetupNotValid: Bool {
        Settings.locationId == nil && Settings.useDemoLocations == false
    }

    func updateLocationsSetup(option: LocationsSetupOption) {
        switch option {
        case .demo: resetToDemoLocations()
        case .custom: resetToCustomLocation()
        }
    }
    
    func updateDemoLocationsSetting(enable: Bool) {
        if enable { resetToDemoLocations() }
        else { resetToCustomLocation() }
    }
    
    func resetToDemoLocations() {
        Settings.customLocation = nil
        Settings.useDemoLocations = true
        storeService.setupDemoLocations()
        locationsSetupCommon()
    }
    
    func resetToCustomLocation() {
        Settings.useDemoLocations = false
        locationsSetupCommon()
    }
    
    private func locationsSetupCommon() {
        updateLocationsPublisher()
        Settings.locationId = nil
        currentLocation = nil
        currentLocationId = nil
    }
}

// MARK: - Private
extension DittoService {
    private func updateLocationsPublisher() {
        allLocationsCancellable = storeService
            .allLocationsObservePublisher()
            .map { locations in
                if Settings.useDemoLocations {
                    return locations.filter { Location.demoLocationsIds.contains($0.id) }
                }
                return locations
            }
            .assign(to: \.allLocations, on: self)
    }


    private func updateOrdersPublisher(_ locId: String) {
        guard let subscription = syncService.ordersSubscription else { return }

        allOrdersCancellable = storeService
            .allOrdersObservePublisher(
                queryString: subscription.queryString,
                queryArgs: subscription.queryArguments
            )
            .assign(to: \.locationOrders, on: self)
    }

    private func updateCurrentLocation(_ locId: String?) {
        guard let locId = locId else { return }
        let location = allLocations.first { $0.id == locId }
        currentLocation = location
        currentLocationSubject.value = location
    }
}

// MARK: - StoreService
fileprivate struct StoreService {
    private let store: DittoStore

    init(_ store: DittoStore) {
        self.store = store
    }

    func insertLocation(of customLoc: CustomLocation) {
        let loc = Location(id: customLoc.locationId, name: customLoc.locationName)
        let query = loc.insertNewQuery
        exec(query: query)
    }

    func insert(order: Order) {
        let query = order.insertNewQuery
        exec(query: query)
    }

    func setupDemoLocations(_ demoLocations: [Location] = Location.demoLocations) {
        demoLocations.forEach { loc in
            let query = loc.insertDefaultQuery
            exec(query: query)
        }
    }

    func add(item: OrderItem, to order: Order) {
        let query = order.addItemQuery(orderItem: item)
        exec(query: query)
    }

    func updateStatus(of order: Order, with status: OrderStatus) {
        let query = order.updateStatusQuery(status: status)
        exec(query: query)
    }

    func clearSaleItemIds(of order: Order) {
        let query = order.clearSaleItemIdsQuery
        exec(query: query)
    }

    func reset(order: Order) {
        let query = order.resetQuery
        exec(query: query)
    }

    func insert(transaction: Transaction) {
        let query = transaction.insertNewQuery
        exec(query: query)
    }

    func add(_ transaction: Transaction, to order: Order) {
        let query = order.addTransactionQuery(transaction: transaction)
        exec(query: query)
    }

    private func exec(query: DittoQuery, function: String = #function) {
        Task {
            do {
                try await self.store.execute(query: query.string, arguments: query.args)
            } catch {
                assertionFailure("ERROR with \(function) \(query.string) \(query.args): " + error.localizedDescription)
            }
        }
    }

    func allLocationsObservePublisher() -> AnyPublisher<[Location], Never> {
        store.observePublisher(query: Location.selectAllQuery.string, mapTo: Location.self)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<[Location], Never>()
            }
            .eraseToAnyPublisher()
    }

    func allOrdersObservePublisher(queryString: String, queryArgs: [String:Any?]?) -> AnyPublisher<[Order], Never> {
        store.observePublisher(query: queryString, arguments: queryArgs, mapTo: Order.self)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<[Order], Never>()
            }
            .eraseToAnyPublisher()
    }

    func selectByIDObservePublisher(_ order: Order) -> AnyPublisher<Order?, Never> {
        let query = order.selectByIDQuery
        return store.observePublisher(query: query.string, arguments: query.args, mapTo: Order.self, onlyFirst: true)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<Order?, Never>()
            }
            .eraseToAnyPublisher()
    }

    func incompleteOrderFuture(locationId: String, deviceId: String) -> Future<Order?, Never> {
        print("DS.\(#function) --> in")
        let query = Order.incompleteOrderQuery(locationId: locationId, deviceId: deviceId)
        return Future { promise in
            Task {
                do {
                    let result = try await self.store.execute(query: query.string, arguments: query.args)
                    if let item = result.items.first {
//                        print("DS.\(#function): incomplete order FOUND")
                        var order = Order(value: item.value)
                        order.createdOn = Date()
                        order.saleItemIds.removeAll()
                        order.status = .open
                        
                        // The returned Order object is only to immediately update the UI by the caller;
                        // a new Order object will be created by the observer when locationOrders is
                        // updated by the following call to reset/update the order in the collection
                        reset(order: order)
                        
                        promise(.success(Order(value: item.value)))
                    } else {
//                        print("DS.\(#function): incomplete order NOT FOUND --> return nil")
                        return promise(.success(nil))
                    }
                } catch {
                    print(
                        "DS.incompleteOrderPublisher: ERROR with  \(query.string) \(query.args):\n"
                        + error.localizedDescription
                    )
                    return promise(.success(nil))
                }
            }
        }
    }
}

// MARK: - SyncService
fileprivate final class SyncService {
    private let sync: DittoSync

    private var locationsSubscription: DittoSyncSubscription? = nil
    private(set) var ordersSubscription: DittoSyncSubscription? = nil

    init(_ sync: DittoSync) {
        self.sync = sync
    }

    func registerInitialSubscriptions() {
        do {
            try locationsSubscription = sync.registerSubscription(
                query: Location.selectAllQuery.string
            )
            try ordersSubscription = sync.registerSubscription(
                query: Order.defaultLocationSyncQuery.string,
                arguments: Order.defaultLocationSyncQuery.args
            )
        } catch {
            assertionFailure("ERROR with \(#function)" + error.localizedDescription)
        }
    }

    func registerOrdersSinceTTLSubscription(locId: String) {
        let query = Order.ordersQuerySinceTTL(locId: locId)
        do {
            ordersSubscription = try sync.registerSubscription(
                query: query.string,
                arguments: query.args
            )
        } catch {
            assertionFailure("ERROR with \(#function)" + error.localizedDescription)
        }
    }

    func cancelOrdersSubscription() {
        ordersSubscription?.cancel()
        ordersSubscription = nil
    }
}
