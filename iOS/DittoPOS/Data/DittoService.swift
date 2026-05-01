//
//  DittoService.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

// MARK: - DittoInstance

/// Owns the `Ditto` instance and starts sync. Split out so `DittoService`
/// can stay focused on this app's collections and lifecycle.
final class DittoInstance: ObservableObject {
    static var shared = DittoInstance()
    let ditto: Ditto

    private init() {
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
        } catch {
            print("ERROR: disableSyncWithV3() failed: \(error)")
        }

        Task {
            do {
                // strict mode off lets DQL use map/object CRDT semantics
                try await ditto.store.execute(query: "ALTER SYSTEM SET DQL_STRICT_MODE = false")
                let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                if !isPreview {
                    try ditto.sync.start()
                }
            } catch {
                print("ERROR: starting sync failed: \(error)")
            }
        }
    }
}

// MARK: - DittoService
//
// Single point of contact between the UI and Ditto: holds the @Published
// state the views observe, registers subscriptions, runs DQL mutations,
// and performs launch-time eviction. Mirrors the Android `DittoRepository`
// shape (one type, no internal sub-services).

@MainActor final class DittoService: ObservableObject {
    static let shared = DittoService()

    @Published private(set) var allLocations: [Location] = []
    @Published private(set) var currentLocation: Location?
    @Published var currentLocationId: String?
    @Published private(set) var locationOrders: [Order] = []
    @Published private(set) var locationSaleItems: [SaleItem] = []

    let ditto = DittoInstance.shared.ditto
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    // Active subscriptions keyed by stable name so we can replace on location change.
    private var subscriptions: [String: DittoSyncSubscription] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var locationsObserver = AnyCancellable({})
    private var ordersObserver = AnyCancellable({})
    private var saleItemsObserver = AnyCancellable({})

    private init() {
        // Locations sync starts immediately; orders + sale_items wait for a chosen location.
        registerSubscription(name: "locations", query: "SELECT * FROM \(Location.collectionName)")

        Task { @MainActor in
            await DemoSeeder(store: store).seedAll()
            await Eviction.runIfDue(store: store)
        }

        observeAllLocations()
        currentLocationId = Settings.locationId

        $currentLocationId
            .combineLatest($allLocations)
            .sink { [weak self] locationId, _ in
                guard let self, let locationId else { return }

                if locationId != Settings.locationId {
                    Settings.locationId = locationId
                }

                if Settings.useDemoLocations {
                    Task { @MainActor in
                        await DemoSeeder(store: self.store).seedLocations()
                    }
                }

                self.activate(locationId: locationId)
            }
            .store(in: &cancellables)
    }

    // MARK: Public — mutations

    func add(order: Order) {
        upsert(order: order)
    }

    func add(item: CartLineItem, lineItemId: String, to order: Order) {
        upsert(order: order.addingCartLineItem(item, lineItemId: lineItemId))
    }

    func updateStatus(of order: Order, with status: OrderStatus) {
        upsert(order: order.appendingStatus(status))
    }

    func addPayment(_ payment: Payment, paymentId: String, to order: Order) {
        upsert(order: order.addingPayment(payment, paymentId: paymentId))
    }

    func clearCart(of order: Order) {
        guard !order.cart.isEmpty else { return }
        let unsetList = order.cart.keys.map { "cart.\"\($0)\"" }.joined(separator: ", ")
        execute(
            """
            UPDATE \(Order.collectionName)
            UNSET \(unsetList)
            WHERE _id.id = :id AND _id.locationId = :locationId
            """,
            args: ["id": order.documentId.id, "locationId": order.documentId.locationId]
        )
    }

    func reset(order: Order) {
        let createdAtNow = Date().formatted(DittoDateFormatting.iso8601)
        var args: [String: Any?] = [
            "id": order.documentId.id,
            "locationId": order.documentId.locationId,
            "createdAt": createdAtNow
        ]
        let setClause = "SET createdAt = :createdAt"
        let whereClause = "WHERE _id.id = :id AND _id.locationId = :locationId"

        if order.cart.isEmpty {
            execute("UPDATE \(Order.collectionName) \(setClause) \(whereClause)", args: args)
        } else {
            let unsetList = order.cart.keys.map { "cart.\"\($0)\"" }.joined(separator: ", ")
            execute(
                "UPDATE \(Order.collectionName) \(setClause) UNSET \(unsetList) \(whereClause)",
                args: args
            )
        }
    }

    /// Persist a user-defined location.
    func saveCustomLocation(company: String, location: String) {
        let customLocation = CustomLocation(companyName: company, locationName: location)
        guard let jsonData = JSONEncoder.encodedObject(customLocation) else { return }
        Settings.customLocation = jsonData

        let asLocation = Location(id: customLocation.locationId, name: customLocation.locationName)
        guard let json = try? asLocation.dittoJSONString() else { return }
        execute(
            """
            INSERT INTO \(Location.collectionName)
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": json]
        )

        currentLocationId = customLocation.locationId
        try? ditto.smallPeerInfo.setMetadata(["locationId": customLocation.locationId])
    }

    // MARK: Public — observers

    /// Observe a single order by composite id.
    func orderPublisher(_ order: Order) -> AnyPublisher<Order, Never> {
        store.observePublisher(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["id": order.documentId.id, "locationId": order.documentId.locationId],
            mapTo: Order.self
        )
        .compactMap(\.first)
        .catch { _ in Empty<Order, Never>() }
        .eraseToAnyPublisher()
    }

    // MARK: Private

    private func upsert(order: Order) {
        guard let json = try? order.dittoJSONString() else { return }
        execute(
            """
            INSERT INTO \(Order.collectionName)
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": json]
        )
    }

    private func activate(locationId: String) {
        registerSubscription(
            name: "orders",
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.locationId = :locationId
                    AND createdAt > :TTL
                """,
            args: ["locationId": locationId, "TTL": DateFormatter.startOfTodayString]
        )
        registerSubscription(
            name: "sale_items",
            query: """
                SELECT * FROM \(SaleItem.collectionName)
                WHERE _id.locationId = :locationId
                ORDER BY name
                """,
            args: ["locationId": locationId]
        )

        observeOrders(locationId: locationId)
        observeSaleItems(locationId: locationId)
        currentLocation = allLocations.first { $0.id == locationId }
    }

    private func registerSubscription(name: String, query: String, args: [String: Any?]? = nil) {
        subscriptions[name]?.cancel()
        do {
            subscriptions[name] = try sync.registerSubscription(query: query, arguments: args)
        } catch {
            assertionFailure("subscribe \(name) failed: \(error.localizedDescription)")
        }
    }

    private func observeAllLocations() {
        locationsObserver = store.observePublisher(
            query: "SELECT * FROM \(Location.collectionName)",
            mapTo: Location.self
        )
        .map { locations in
            // Demo mode hides custom locations from other peers.
            if Settings.useDemoLocations {
                return locations.filter { LocationSeed.demoLocationIds.contains($0.id) }
            }
            return locations
        }
        .replaceError(with: [])
        .assign(to: \.allLocations, on: self)
    }

    private func observeOrders(locationId: String) {
        guard let sub = subscriptions["orders"] else { return }
        ordersObserver = store.observePublisher(
            query: sub.queryString,
            arguments: sub.queryArguments,
            mapTo: Order.self
        )
        .replaceError(with: [])
        .assign(to: \.locationOrders, on: self)
    }

    private func observeSaleItems(locationId: String) {
        guard let sub = subscriptions["sale_items"] else { return }
        saleItemsObserver = store.observePublisher(
            query: sub.queryString,
            arguments: sub.queryArguments,
            mapTo: SaleItem.self
        )
        .replaceError(with: [])
        .assign(to: \.locationSaleItems, on: self)
    }

    private func execute(_ query: String, args: [String: Any?] = [:], function: String = #function) {
        Task {
            do {
                _ = try await store.execute(query: query, arguments: args)
            } catch {
                assertionFailure("DQL \(function) failed: \(error.localizedDescription)\n\(query)")
            }
        }
    }
}

// MARK: - Demo / Custom location toggle (carried over; removed in BP/sync-group-and-routing-hint)

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
        if enable { resetToDemoLocations() } else { resetToCustomLocation() }
    }

    func resetToDemoLocations() {
        Settings.customLocation = nil
        Settings.useDemoLocations = true
        Task { @MainActor in
            await DemoSeeder(store: store).seedLocations()
        }
        clearLocationSelection()
    }

    func resetToCustomLocation() {
        Settings.useDemoLocations = false
        clearLocationSelection()
    }

    private func clearLocationSelection() {
        observeAllLocations()
        Settings.locationId = nil
        currentLocation = nil
        currentLocationId = nil
    }
}

// MARK: - Eviction
//
// Storage cleanup on app launch, gated to at most once per 24h. Observer
// queries filter by location/TTL, so this is purely about preventing the
// local store from accumulating expired orders.

private enum Eviction {
    private static let lastRunKey = "v2.lastEvictionAt"
    private static let interval: TimeInterval = 60 * 60 * 24

    static func runIfDue(store: DittoStore) async {
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: lastRunKey)
        guard now - last >= interval else { return }

        let ttl = DateFormatter.startOfTodayString
        do {
            _ = try await store.execute(
                query: "EVICT FROM \(Order.collectionName) WHERE createdAt <= :TTL",
                arguments: ["TTL": ttl]
            )
            UserDefaults.standard.set(now, forKey: lastRunKey)
            print("Eviction: evicted orders with createdAt <= \(ttl)")
        } catch {
            print("Eviction: ERROR \(error.localizedDescription)")
        }
    }
}
