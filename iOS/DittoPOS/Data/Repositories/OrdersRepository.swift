//
//  OrdersRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

/// Owns the `pos_orders` collection: registers the per-location subscription,
/// observes the synced documents, runs DQL mutations, and gates startup
/// eviction. Mirrors Android's `OrdersRepository`.
@MainActor final class OrdersRepository: ObservableObject {

    @Published private(set) var locationOrders: [Order] = []

    private let dittoManager: DittoManager
    private var ditto: Ditto { dittoManager.ditto }
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var observer = AnyCancellable({})
    private var locationSubscription = AnyCancellable({})

    init(dittoManager: DittoManager = .shared, locationsRepository: LocationsRepository) {
        self.dittoManager = dittoManager
        // Pull the active location from LocationsRepository and re-register
        // the subscription on every change. @Published replays the current
        // value on subscribe, so cold-start activation comes through here.
        locationSubscription = locationsRepository.$currentLocationId
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] locationId in
                self?.setActiveLocation(locationId)
            }
    }

    // MARK: Subscription

    private func setActiveLocation(_ locationId: String) {
        subscription?.cancel()
        let args: [String: Any?] = ["locationId": locationId, "TTL": DateFormatter.startOfTodayString]

        // Subscription = the sync set: this location's orders since TTL. A failed
        // registration must NOT skip the observer below — the observer is a local
        // read over the store, independent of the sync set, so the UI still shows
        // documents already present locally (matches Android's separation).
        do {
            subscription = try sync.registerSubscription(
                query: """
                    SELECT * FROM \(Order.collectionName)
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
                    """,
                arguments: args
            )
        } catch {
            reportSubscriptionFailure("subscribe orders", error)
        }

        // Observer = the local read that drives the UI. Its own query string,
        // independent of the subscription's success.
        observer = store.observePublisher(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.locationId = :locationId
                    AND createdAt > :TTL
                """,
            arguments: args,
            mapTo: Order.self
        )
        .replaceError(with: [])
        .assign(to: \.locationOrders, on: self)
    }

    // MARK: Single-order observation (used by KDS tile views)

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

    // MARK: Mutations

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
        // UNSET target paths can't be parameterized in DQL, so the cart keys
        // (app-generated line-item UUIDs) are interpolated; all values use :named args.
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
        let createdAtNow = DittoWireDate.string(from: Date())
        let args: [String: Any?] = [
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

    // MARK: Eviction
    //
    // Storage cleanup on app launch, gated to at most once per 24h. Observer
    // queries filter by location/TTL, so this is purely about preventing the
    // local store from accumulating expired orders.

    func runEvictionIfDue() async {
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: Eviction.lastRunKey)
        guard now - last >= Eviction.interval else { return }

        let ttl = DateFormatter.startOfTodayString
        do {
            _ = try await store.execute(
                query: "EVICT FROM \(Order.collectionName) WHERE createdAt <= :TTL",
                arguments: ["TTL": ttl]
            )
            UserDefaults.standard.set(now, forKey: Eviction.lastRunKey)
            print("Eviction: evicted orders with createdAt <= \(ttl)")
        } catch {
            print("Eviction: ERROR \(error.localizedDescription)")
        }
    }

    private enum Eviction {
        static let lastRunKey = "v2.lastEvictionAt"
        static let interval: TimeInterval = 60 * 60 * 24
    }

    // MARK: Helpers

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
