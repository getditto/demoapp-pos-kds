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

    @Published private(set) var allLocations = [Location]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?
    @Published private(set) var currentLocation: Location?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)

    @Published private(set) var locationOrders = [Order]()
    private var allOrdersCancellable = AnyCancellable({})

    private(set) var deviceId: String //ditto.siteID as String to partition ordering to devices

    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto
    private let storeService: StoreService
    private let syncService: SyncService

    private init() {
        storeService = StoreService(ditto.store)
        syncService = SyncService(ditto.sync)
        syncService.registerInitialSubscriptions()

        deviceId = String(ditto.siteID)

        // make sure our log level is set _before_ starting ditto.
        loggingOption = UserDefaults.standard.storedLoggingOption
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
            storeService.insertLocation(of: user)

            // setting here will save locId and update subscriptions
            currentLocationId = user.locationId
        }
        .store(in: &cancellables)

        if USE_DEFAULT_LOCATIONS {
            storeService.setupDemoLocations()
        }

        updateLocationsPublisher()

        $currentLocationId
            .combineLatest($allLocations)
            .sink {[weak self] locId, allLocations in
                guard let locId = locId, let self = self else { return }
                saveLocationId(locId)
                self.allLocations = allLocations

                // reset subscription for new location
                syncService.cancelOrdersSubscription()
                syncService.registerOrdersSinceTTLSubscription(locId: locId)

                updateOrdersPublisher(locId)
                updateCurrentLocation(locId)
            }
            .store(in: &cancellables)

        self.currentLocationId = self.storedLocationId
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
        // NOTE:
        //   DQL v1 (4.5.x) doesn't support write transactions, so these are written to the store asynchronously for now.
        storeService.insert(transaction: transx)
        storeService.add(transx, to: order)
    }

    func restoredIncompleteOrder(for locId: String?) -> AnyPublisher<Order, Never> {
        guard let locId = locId ?? UserDefaults.standard.storedLocationId else {
            return Empty().eraseToAnyPublisher()
        }

        return storeService.incompleteOrderPublisher(locationId: locId, deviceId: deviceId)
            .compactMap { $0 } // Ignore nil
            .map { [weak self] imcompleteOrder in
                guard let self = self else { return imcompleteOrder }
                var order = imcompleteOrder
                self.reset(order: order)
                order.createdOn = Date()
                order.saleItemIds.removeAll()
                order.status = .open
                // The returned Order object is only to immediately update the UI by the caller;
                // a new Order object will be created with the values mutated in resetOrderDoc()
                // when the liveQuery/Publisher is fired by the update
                return order
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private
extension DittoService {
    private func updateLocationsPublisher() {
        if USE_DEFAULT_LOCATIONS {
            allLocationsCancellable = storeService
                .allLocationsObservePublisher()
                .map { locations in
                    locations.filter { Location.demoLocationsIds.contains($0.id) }
                }
                .assign(to: \.allLocations, on: self)
        } else {
            allLocationsCancellable = storeService
                .allLocationsObservePublisher()
                .assign(to: \.allLocations, on: self)
        }
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

// MARK: - UserDefaults
extension DittoService {
    private var storedLocationId: String? {
        UserDefaults.standard.storedLocationId
    }
    private func saveLocationId(_ newId: String) {
        UserDefaults.standard.storedLocationId = newId
    }
}

// MARK: - Logging
extension DittoService {
    private func resetLogging() {
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

// MARK: - DittoInstance
final class DittoInstance {
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

        try! ditto.disableSyncWithV3()
    }
}

// MARK: - StoreService
fileprivate struct StoreService {
    private let store: DittoStore

    init(_ store: DittoStore) {
        self.store = store
    }

    func insertLocation(of user: User) {
        let loc = Location(id: user.locationId, name: user.locationName)
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
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func incompleteOrderPublisher(locationId: String, deviceId: String) -> AnyPublisher<Order?, Never> {
        let query = Order.incompleteOrderQuery(locationId: locationId, deviceId: deviceId)
        return store.observePublisher(query: query.string, arguments: query.args, mapTo: Order.self, onlyFirst: true)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<Order?, Never>()
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

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
