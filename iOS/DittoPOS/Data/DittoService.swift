///
//  DittoService.swift
//  DittoPOS
//
//  Created by Eric Turner on 2/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift

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
            transportConfig.connect.webSocketURLs.insert(Env.DITTO_WEBSOCKET_URL)
        }

        do {
            try ditto.disableSyncWithV3()
        } catch let error {
            print("ERROR: disableSyncWithV3() failed with error \"\(error)\"")
        }

        Task {
            do {
                // disable strict mode - allows for DQL with counters and objects as CRDT maps
                try await ditto.store.execute(query: "ALTER SYSTEM SET DQL_STRICT_MODE = false")

                let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                if !isPreview {
                    try ditto.sync.start()
                }
            } catch let error {
                print("ERROR: Setting DQL_STRICT_MODE or starting sync failed with error \"\(error)\"")
            }
        }
    }
}

@MainActor class DittoService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var allLocations = [Location]()
    private var allLocationsCancellable = AnyCancellable({})

    @Published var currentLocationId: String?
    @Published private(set) var currentLocation: Location?
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)

    @Published private(set) var locationOrders = [Order]()
    private var allOrdersCancellable = AnyCancellable({})

    @Published private(set) var locationSaleItems = [SaleItem]()
    private var saleItemsCancellable = AnyCancellable({})

    static var shared = DittoService()
    let ditto = DittoInstance.shared.ditto

    private let storeService: StoreService
    private let syncService: SyncService

    private init() {
        storeService = StoreService(ditto.store)
        syncService = SyncService(ditto.sync)
        syncService.registerLocationsSubscription()

        Task { @MainActor in
            await DemoSeeder(store: ditto.store).seedAll()
            await Eviction.runIfDue(store: ditto.store)
        }

        updateLocationsPublisher()

        currentLocationId = Settings.locationId

        $currentLocationId
            .combineLatest($allLocations)
            .sink {[weak self] locationId, _ in
                guard let locationId = locationId, let self = self else { return }

                if locationId != Settings.locationId {
                    Settings.locationId = locationId
                }

                if Settings.useDemoLocations {
                    Task { @MainActor in
                        await DemoSeeder(store: self.ditto.store).seedLocations()
                    }
                }

                syncService.cancelOrdersSubscription()
                syncService.cancelSaleItemsSubscription()
                syncService.registerOrdersSinceTTLSubscription(locationId: locationId)
                syncService.registerSaleItemsSubscription(locationId: locationId)

                updateOrdersPublisher(locationId)
                updateSaleItemsPublisher(locationId)
                updateCurrentLocation(locationId)
            }
            .store(in: &cancellables)
    }

    // use case: store user-defined location
    func saveCustomLocation(company: String, location: String) {
        let customLocation = CustomLocation(companyName: company, locationName: location)
        guard let jsonData = JSONEncoder.encodedObject(customLocation) else {
            print("DS.\(#function): jsonData from custom location FAILED --> RETURN")
            return
        }

        Settings.customLocation = jsonData

        storeService.insertLocation(of: customLocation)

        currentLocationId = customLocation.locationId

        do {
            try ditto.smallPeerInfo.setMetadata(["locationId": customLocation.locationId])
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
        storeService.upsert(order: order)
    }

    func add(item: CartLineItem, lineItemId: String, to order: Order) {
        let updated = order.addingCartLineItem(item, lineItemId: lineItemId)
        storeService.upsert(order: updated)
    }

    func updateStatus(of order: Order, with status: OrderStatus) {
        let updated = order.appendingStatus(status)
        storeService.upsert(order: updated)
    }

    func clearCart(of order: Order) {
        storeService.clearCart(of: order)
    }

    func reset(order: Order) {
        storeService.reset(order: order)
    }

    func addPayment(_ payment: Payment, paymentId: String, to order: Order) {
        let updated = order.addingPayment(payment, paymentId: paymentId)
        storeService.upsert(order: updated)
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
        Task { @MainActor in
            await DemoSeeder(store: ditto.store).seedLocations()
        }
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
                    return locations.filter { LocationSeed.demoLocationIds.contains($0.id) }
                }
                return locations
            }
            .assign(to: \.allLocations, on: self)
    }

    private func updateOrdersPublisher(_ locationId: String) {
        guard let subscription = syncService.ordersSubscription else { return }

        allOrdersCancellable = storeService
            .allOrdersObservePublisher(
                queryString: subscription.queryString,
                queryArgs: subscription.queryArguments
            )
            .assign(to: \.locationOrders, on: self)
    }

    private func updateSaleItemsPublisher(_ locationId: String) {
        guard let subscription = syncService.saleItemsSubscription else { return }
        saleItemsCancellable = storeService
            .allSaleItemsObservePublisher(
                queryString: subscription.queryString,
                queryArgs: subscription.queryArguments
            )
            .assign(to: \.locationSaleItems, on: self)
    }

    private func updateCurrentLocation(_ locationId: String?) {
        guard let locationId = locationId else { return }
        let location = allLocations.first { $0.id == locationId }
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

    func insertLocation(of customLocation: CustomLocation) {
        let location = Location(id: customLocation.locationId, name: customLocation.locationName)
        guard let json = try? location.dittoJSONString() else { return }
        exec(
            """
            INSERT INTO \(Location.collectionName)
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": json]
        )
    }

    func upsert(order: Order) {
        guard let json = try? order.dittoJSONString() else { return }
        exec(
            """
            INSERT INTO \(Order.collectionName)
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": json]
        )
    }

    func clearCart(of order: Order) {
        guard !order.cart.isEmpty else { return }
        let unsetList = order.cart.keys.map { "cart.\"\($0)\"" }.joined(separator: ", ")
        exec(
            """
            UPDATE \(Order.collectionName)
            UNSET \(unsetList)
            WHERE _id.id = :id AND _id.locationId = :locationId
            """,
            args: ["id": order._id.id, "locationId": order._id.locationId]
        )
    }

    func reset(order: Order) {
        let createdAtNow = DateFormatter.isoDate.string(from: Date())
        var args: [String: Any?] = [
            "id": order._id.id,
            "locationId": order._id.locationId,
            "createdAt": createdAtNow
        ]
        if order.cart.isEmpty {
            exec(
                """
                UPDATE \(Order.collectionName)
                SET createdAt = :createdAt
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
                args: args
            )
        } else {
            let unsetList = order.cart.keys.map { "cart.\"\($0)\"" }.joined(separator: ", ")
            exec(
                """
                UPDATE \(Order.collectionName)
                SET createdAt = :createdAt
                UNSET \(unsetList)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
                args: args
            )
        }
    }

    private func exec(_ query: String, args: [String: Any?] = [:], function: String = #function) {
        Task {
            do {
                try await self.store.execute(query: query, arguments: args)
            } catch {
                assertionFailure("ERROR with \(function) \(query) \(args): " + error.localizedDescription)
            }
        }
    }

    func allLocationsObservePublisher() -> AnyPublisher<[Location], Never> {
        store.observePublisher(
            query: "SELECT * FROM \(Location.collectionName)",
            mapTo: Location.self
        )
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<[Location], Never>()
            }
            .eraseToAnyPublisher()
    }

    func allOrdersObservePublisher(queryString: String, queryArgs: [String: Any?]?) -> AnyPublisher<[Order], Never> {
        store.observePublisher(query: queryString, arguments: queryArgs, mapTo: Order.self)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<[Order], Never>()
            }
            .eraseToAnyPublisher()
    }

    func allSaleItemsObservePublisher(queryString: String, queryArgs: [String: Any?]?) -> AnyPublisher<[SaleItem], Never> {
        store.observePublisher(query: queryString, arguments: queryArgs, mapTo: SaleItem.self)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<[SaleItem], Never>()
            }
            .eraseToAnyPublisher()
    }

    func selectByIDObservePublisher(_ order: Order) -> AnyPublisher<Order?, Never> {
        store.observePublisher(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["id": order._id.id, "locationId": order._id.locationId],
            mapTo: Order.self
        )
            .map(\.first)
            .catch { error in
                assertionFailure("ERROR with \(#function)" + error.localizedDescription)
                return Empty<Order?, Never>()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SyncService
fileprivate final class SyncService {
    private let sync: DittoSync

    private var locationsSubscription: DittoSyncSubscription?
    private(set) var ordersSubscription: DittoSyncSubscription?
    private(set) var saleItemsSubscription: DittoSyncSubscription?

    init(_ sync: DittoSync) {
        self.sync = sync
    }

    /// Locations sub is the only one that runs at startup; orders and sale_items
    /// register lazily once a location is chosen.
    func registerLocationsSubscription() {
        do {
            locationsSubscription = try sync.registerSubscription(
                query: "SELECT * FROM \(Location.collectionName)"
            )
        } catch {
            assertionFailure("ERROR with \(#function)" + error.localizedDescription)
        }
    }

    func registerOrdersSinceTTLSubscription(locationId: String) {
        do {
            ordersSubscription = try sync.registerSubscription(
                query: """
                    SELECT * FROM \(Order.collectionName)
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
                    """,
                arguments: ["locationId": locationId, "TTL": DateFormatter.startOfTodayString]
            )
        } catch {
            assertionFailure("ERROR with \(#function)" + error.localizedDescription)
        }
    }

    func cancelOrdersSubscription() {
        ordersSubscription?.cancel()
        ordersSubscription = nil
    }

    func registerSaleItemsSubscription(locationId: String) {
        do {
            saleItemsSubscription = try sync.registerSubscription(
                query: """
                    SELECT * FROM \(SaleItem.collectionName)
                    WHERE _id.locationId = :locationId
                    ORDER BY name
                    """,
                arguments: ["locationId": locationId]
            )
        } catch {
            assertionFailure("ERROR with \(#function)" + error.localizedDescription)
        }
    }

    func cancelSaleItemsSubscription() {
        saleItemsSubscription?.cancel()
        saleItemsSubscription = nil
    }
}

// MARK: - Eviction

/// Storage cleanup on app launch, gated to at most once per 24h.
/// Observer queries filter by location/TTL, so this is purely about
/// preventing the local store from accumulating expired orders.
fileprivate enum Eviction {
    private static let lastRunKey = "v2.lastEvictionAt"
    private static let interval: TimeInterval = 60 * 60 * 24

    static func runIfDue(store: DittoStore) async {
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: lastRunKey)
        guard now - last >= interval else { return }

        do {
            _ = try await store.execute(
                query: "EVICT FROM \(Order.collectionName) WHERE createdAt <= :TTL",
                arguments: ["TTL": DateFormatter.startOfTodayString]
            )
            UserDefaults.standard.set(now, forKey: lastRunKey)
        } catch {
            print("Eviction: ERROR \(error.localizedDescription)")
        }
    }
}
