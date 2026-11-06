//
//  OrdersRepository.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

@MainActor final class OrdersRepository: ObservableObject {

    let locationPublisher: AnyPublisher<String?, Never>

    private let ditto: Ditto
    private let now: () -> Date
    private let defaults: UserDefaults
    private let calendar: Calendar
    private var store: DittoStore { ditto.store }
    private var sync: DittoSync { ditto.sync }

    private var subscription: DittoSyncSubscription?
    private var subscriptionCutoff: String
    private var activeLocationId: String?
    private var isEvicting = false
    private var locationSubscription = AnyCancellable({})

    init(
        ditto: Ditto, locationPublisher: AnyPublisher<String?, Never>, now: @escaping () -> Date = Date.init,
        defaults: UserDefaults = .standard, calendar: Calendar = .current
    ) {
        self.ditto = ditto
        self.now = now
        self.defaults = defaults
        self.calendar = calendar
        let lastRun = defaults.double(forKey: OrderEviction.lastRunKey)
        let retainedSince = lastRun > 0 ? Date(timeIntervalSince1970: lastRun) : now()
        subscriptionCutoff = DittoWireDate.string(from: calendar.startOfDay(for: retainedSince))
        self.locationPublisher = locationPublisher
        locationSubscription = locationPublisher
            .removeDuplicates()
            .sink { [weak self] locationId in
                self?.setActiveLocation(locationId)
            }
    }

    // MARK: Subscription

    private func setActiveLocation(_ locationId: String?) {
        activeLocationId = locationId
        subscription?.cancel()
        subscription = nil
        guard let locationId, !isEvicting else { return }
        let args: [String: Any?] = ["locationId": locationId, "TTL": subscriptionCutoff]

        // Sync registration is independent of visible consumers' local queries.
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

    }

    func observeLocationOrders(_ locationId: String) -> AnyPublisher<[Order], Error> {
        store.observePublisher(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.locationId = :locationId
                """,
            arguments: ["locationId": locationId],
            mapTo: Order.self
        )
    }

    // MARK: Selected POS order observation

    func observeOrder(_ id: DocumentID) -> AnyPublisher<Order?, Error> {
        store.observePublisher(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["id": id.id, "locationId": id.locationId],
            mapTo: Order.self
        )
        .map(\.first)
        .eraseToAnyPublisher()
    }

    // MARK: Mutations

    func add(order: Order) async throws {
        try await Self.execute(
            store: store,
            query: "INSERT INTO \(Order.collectionName) DOCUMENTS (deserialize_json(:json)) ON ID CONFLICT DO UPDATE_LOCAL_DIFF",
            args: ["json": try order.dittoJSONString()])
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
        // App-generated UUID paths need quoted identifiers, not DQL value arguments.
        // https://docs.ditto.live/dql/update
        let unsetList = order.cart.keys.map { "cart.`\($0)`" }.joined(separator: ", ")
        execute(
            """
            UPDATE \(Order.collectionName)
            UNSET \(unsetList)
            WHERE _id.id = :id AND _id.locationId = :locationId
            """,
            args: ["id": order.documentId.id, "locationId": order.documentId.locationId]
        )
    }

    // A hidden POS snapshot can predate a payment or cancellation.
    func resetUnpaidOrder(_ id: DocumentID) async throws {
        guard let order = try await Self.readOrder(id, store: store), !order.isPaid else { return }
        let createdAtNow = DittoWireDate.string(from: now())
        let args: [String: String] = [
            "id": order.documentId.id,
            "locationId": order.documentId.locationId,
            "createdAt": createdAtNow
        ]
        let setClause = "SET createdAt = :createdAt"
        let whereClause = "WHERE _id.id = :id AND _id.locationId = :locationId"
        let query: String
        if order.cart.isEmpty {
            query = "UPDATE \(Order.collectionName) \(setClause) \(whereClause)"
        } else {
            let unsetList = order.cart.keys.map { "cart.`\($0)`" }.joined(separator: ", ")
            query = "UPDATE \(Order.collectionName) \(setClause) UNSET \(unsetList) \(whereClause)"
        }
        try await Self.execute(store: store, query: query, args: args)
    }

    // MARK: Eviction

    func runEvictionIfDue() async {
        let eviction = OrderEviction(
            now: now,
            calendar: calendar,
            lastRun: { self.defaults.double(forKey: OrderEviction.lastRunKey) },
            recordRun: { self.defaults.set($0, forKey: OrderEviction.lastRunKey) },
            evict: { [self] cutoff in
                // An active subscription can fetch evicted documents again.
                // https://docs.ditto.live/sdk/latest/crud/delete#evicting-data
                isEvicting = true
                subscription?.cancel()
                subscription = nil
                defer {
                    isEvicting = false
                    setActiveLocation(activeLocationId)
                }
                _ = try await store.execute(
                    query: "EVICT FROM \(Order.collectionName) WHERE createdAt <= :TTL",
                    arguments: ["TTL": cutoff]
                )
                subscriptionCutoff = cutoff
            }
        )
        do {
            if let cutoff = try await eviction.runIfDue() {
                print("Eviction: evicted orders with createdAt <= \(cutoff)")
            }
        } catch {
            print("Eviction: ERROR \(error.localizedDescription)")
        }
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

    private func execute(_ query: String, args: [String: String] = [:], function: String = #function) {
        let store = store
        Task {
            do {
                try await Self.execute(store: store, query: query, args: args)
            } catch {
                assertionFailure("DQL \(function) failed: \(error.localizedDescription)\n\(query)")
            }
        }
    }

    // Non-Sendable query arguments need a single owner across the Swift actor boundary.
    private nonisolated static func readOrder(_ id: DocumentID, store: DittoStore) async throws -> Order? {
        let result = try await store.execute(
            query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": id.id, "locationId": id.locationId])
        let orders: [Order] = result.decodeOrSkip()
        return orders.first
    }

    private nonisolated static func execute(store: DittoStore, query: String, args: [String: String]) async throws {
        let arguments: [String: Any?] = args.mapValues { $0 }
        _ = try await store.execute(query: query, arguments: arguments)
    }
}
