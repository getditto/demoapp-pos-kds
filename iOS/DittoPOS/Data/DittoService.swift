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
import OSLog
import SwiftUI

// MARK: - DittoInstance
final class DittoInstance {
    static var shared = DittoInstance()
    let ditto: Ditto

    private init() {
        // Assign new directory to avoid conflict with the old SkyService version.
        let persistenceDirURL = try? FileManager()
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto-pos-demo")

        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID,
            token: Env.DITTO_PLAYGROUND_TOKEN,
            enableDittoCloudSync: true
        ), persistenceDirectory: persistenceDirURL)

        // Sync Small Peer Info to Big Peer
        ditto.smallPeerInfo.isEnabled = true
        ditto.smallPeerInfo.syncScope = .bigPeerOnly

        try! ditto.disableSyncWithV3()
    }
}

let defaultLoggingOption: DittoLogger.LoggingOptions = .error

class DittoService: ObservableObject {

    /*
     re-enable this before commit
     */
//    @Published var loggingOption: DittoLogger.LoggingOptions
    @Published var loggingOption = DittoLogger.LoggingOptions.error
    
    
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var allLocations = [Location]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?
    @Published private(set) var currentLocation: Location?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)

    @Published private(set) var locationOrders = [Order]()
    private var allOrdersCancellable = AnyCancellable({})
    
    @Published private(set) var appConfig = Settings.storedAppConfig ?? AppConfig.Defaults.defaultConfig
    private var appConfigCancellable = AnyCancellable({})
    
    //ditto.siteID as String to partition ordering to devices
    private(set) var deviceId: String

    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto
    private let storeService: StoreService
    let syncService: SyncService //made public for eviction

    private init() {
        // instantiate only the minimum
        storeService = StoreService(ditto.store)
        syncService = SyncService(ditto.sync)
        deviceId = String(ditto.siteID)
        
        /* Run the rest of setup that was previously in init() as background task so that
         the initialization can return quickly enough for the singleton instance to be
         available early elsewhere, e.g. in other initializers.
         N.B. this has the consequence of causing the current order to delay appearing in the
         POS view for a full second or more after launch.
         */
        Task { setup() }
        
        $appConfig
            .sink { config in
                print("   -------- DS.$appConfig.sink ----------\n\(config)")
            }
            .store(in: &cancellables)
    }
        
    private func setup() {
//        storeService = StoreService(ditto.store)
//        syncService = SyncService(ditto.sync)
        syncService.registerInitialSubscriptions()

//        deviceId = String(ditto.siteID)

//        if Settings.useLocalAppConfig {
//            appConfig = Settings.localAppConfig ?? AppConfig.Defaults.defaultConfig
//        }
        // make sure our log level is set _before_ starting ditto.
        loggingOption = Settings.dittoLoggingOption
        $loggingOption
            .sink {[weak self] option in
                Settings.dittoLoggingOption = option
                self?.resetLogging()
            }
            .store(in: &cancellables)

        // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
        let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            try! ditto.startSync()
        }
        
        updateLocationsPublisher()
        
        currentLocationId = Settings.locationId
        
        $currentLocationId
            .combineLatest($allLocations)
            .sink {[weak self] locId, allLocations in
                guard let locId = locId, let self = self else { return }
                
                Logger.ditto.info("currentLocationId(\(locId,privacy:.public)) + allLocations update sink ")
                if locId != Settings.locationId {
                    Settings.locationId = locId
                }

                if Settings.useDemoLocations {
                    storeService.setupDemoLocations()
                }

                //moved above subscription registration
                if Settings.usePublishedAppConfig {
                    enablePublishedAppConfig(locId: locId)
//                    syncService.registerAppConfigSubscription(locId: locId)
//                    updateAppConfigPublisher(locId: locId)
                }

                // reset orders subscription for new location
//                if let ttl = appConfig.TTLs?[ordersKey] {
//                    syncService.cancelOrdersSubscription()
//                    syncService.registerOrdersSinceTTLSubscription(locId: locId, ttl: ttl)
//                    updateOrdersPublisher(locId)
//                }
                resetOrdersSubscription(ttl: appConfig.TTLs?[ordersKey])
                
                Task {
                    await MainActor.run {[weak self] in
                        self?.updateCurrentLocation(locId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func resetOrdersSubscription(ttl: TimeInterval? = nil) {
        Logger.ditto.debug("DS.\(#function) -> in")
        guard let locId = currentLocationId else {
            Logger.ditto.error("DS.\(#function): Error: currentLocationId NIL --> return")
            return
        }
        let ttl = ttl ?? Order.defaultOrdersTTL
        syncService.cancelOrdersSubscription()
        syncService.registerOrdersSinceTTLSubscription(locId: locId, ttl: ttl)
        updateOrdersPublisher(locId)
    }

    // use case: store user-defined location
    func saveCustomLocation(company: String, location: String) {
        let loc = CustomLocation(companyName: company, locationName: location)
        guard let jsonData = try? JSONEncoder().encode(loc) else {
            print("DS.\(#function): jsonData from custom location FAILED --> RETURN")
            return
        }

        Settings.customLocation = jsonData
        
        storeService.insertLocation(of: loc)

        // set currentLocationId: causes save and update subscriptions in currentLocationId.sink in init() above
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

    /* EVICTION: in testing evictions it was found that if the current order is evicted, the
     addOrder workflow no longer works because there is no order.
     Similarly, it seems, when an order is "cleared" with the cancel button, the order should be
     reset back to a new order state. The only difference between order.clearSaleItems query and
     the reset query is that the date is set to now in reset.
    func clearSaleItemIds(of order: Order) {
        storeService.clearSaleItemIds(of: order)
    }
     */
    
    func reset(order: Order) {
        storeService.reset(order: order)
    }

    func updateOrderTransaction(_ order: Order, with transx: Transaction) {
        // NOTE: DQL v1 (4.7.x) doesn't support write/batch transactions, so these
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

    //new appConfig: called when app comes to foreground
    func updateOrders() {
        guard let locId = currentLocationId else {
            Logger.ditto.debug("\(#function,privacy:.public): currentLocationId is nil. Return")
            return
        }
        Logger.ditto.info("\(#function,privacy:.public) --> in")
        updateOrdersPublisher(locId)
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
}

// MARK: - Logging
extension DittoService {
    private func resetLogging() {
        let logOption = Settings.dittoLoggingOption
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

//WIP appConfig
extension DittoService {
    
    func enablePublishedAppConfig(locId: String? = nil) {
        let locId = locId ?? currentLocationId!
        if Settings.usePublishedAppConfig == false { Settings.usePublishedAppConfig = true }
        syncService.registerAppConfigSubscription(locId: locId)
        updateAppConfigPublisher(locId: locId)
    }
    
    func publishAppConfig(_ config: AppConfig) async throws {
        guard let locId = currentLocationId else {
            Logger.ditto.error("DS.\(#function,privacy:.public): ERROR - locId should not be NIL here. --> Return")
            return
        }
        
        Logger.ditto.warning("DS.\(#function,privacy:.public): publish AppConfig")
        
        //new try always saving to UserDefaults for access at launch DittoService initialization
        Settings.storedAppConfig = config
        Settings.usePublishedAppConfig = true
        syncService.registerAppConfigSubscription(locId: locId)
        
        do {
            try await storeService.insertAppConfig(config)
            await MainActor.run {
                updateAppConfigPublisher(locId: locId)
            }
        } catch {
            throw error
        }
    }
    
    func updateLocalOnlyAppConfig(_ config: AppConfig) {
        // save config to settings
        Settings.storedAppConfig = config
        Settings.usePublishedAppConfig = false
        
        // call SyncService to unsubscribe from config
        syncService.unregisterAppConfigSubscription()

        // set self appConfig
        Task {
            await MainActor.run { appConfig = config }
            await MainActor.run { updateOrders() }
        }
    }

    private func updateAppConfigPublisher(locId: String) {
        appConfigCancellable = storeService
            .appConfigObservePublisher(locId: locId)
            .assign(to: \.appConfig, on: self)
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

    /* EVICTION: in testing evictions it was found that if the current order is evicted, the
     addOrder workflow no longer works because there is no order.
     Similarly, it seems, when an order is "cleared" with the cancel button, the order should be
     reset back to a new order state. The only difference between order.clearSaleItems query and
     the reset query is that the date is set to now in reset.
    func clearSaleItemIds(of order: Order) {
        let query = order.clearSaleItemIdsQuery
        exec(query: query)
    }
     */
    
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
//        print("DS.\(#function) --> in")
        
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
    
    func insertAppConfig(_ config: AppConfig) async throws {
        print("DS.\(#function) --> in")
        
        //Eviction MVP: default query inserts to configuration collection
        let query = AppConfig.Defaults.insertQuery(config: config)
            do {
                try await store.execute(query: query.string, arguments: query.args)
            } catch {
                Logger.eviction.error("\(#function,privacy:.public): Error: \(error.localizedDescription,privacy:.public)")
                throw error
            }
    }
    
    func appConfigObservePublisher(locId: String) -> AnyPublisher<AppConfig, Never> {
        let query = AppConfig.Defaults.registerQuery(locId: locId)
        let subject = PassthroughSubject<AppConfig, Never>()
        let defaultConfig = AppConfig.Defaults.defaultConfig

        do {
            try store.registerObserver(query: query.string, arguments: query.args) { result in
                
                // take the latest version
                // N.B. this could be problematic - should there be a better strategy for
                // evaluating which version to update to? Or punt here for demo MVP?
                if let item = result.items.sorted(by: { $0.value["version"] as! Float > $1.value["version"] as! Float }).first {
                    let config = AppConfig(value: item.value)
                    subject.send(config)
//                    return
                }
                
//                Logger.test.warning("DS.appConfigPublisher: registerObserver returned NIL config --> return defaultConfig")
//                subject.send( defaultConfig )
            }
        } catch {
            subject.send( defaultConfig )
            Logger.test.error("DS.appConfigPublisher: register appConfig observer failed: \(error.localizedDescription) --> return defaultConfig")
        }

        return subject.eraseToAnyPublisher()
    }
}
