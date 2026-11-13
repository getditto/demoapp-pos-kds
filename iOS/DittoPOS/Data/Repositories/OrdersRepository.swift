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
        subscription = try! sync.registerSubscription(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.locationId = :locationId
                    AND createdAt > :TTL
                """,
            arguments: args
        )
    }

    func observeLocationOrders(_ locationId: String) -> AnyPublisher<[Order], Never> {
        observeOrders(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.locationId = :locationId
                """,
            arguments: ["locationId": locationId]
        )
    }

    // MARK: Selected POS order observation

    func observeOrder(_ id: DocumentID) -> AnyPublisher<Order?, Never> {
        observeOrders(
            query: """
                SELECT * FROM \(Order.collectionName)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["id": id.id, "locationId": id.locationId]
        )
        .map(\.first)
        .eraseToAnyPublisher()
    }

    private func observeOrders(query: String, arguments: [String: Any?]) -> AnyPublisher<[Order], Never> {
        store.observePublisher(query: query, arguments: arguments, mapTo: Order.self)
            .map { [store] orders in
                Deferred { OrderPreparation(orders: orders, store: store).publisher }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    // MARK: Mutations

    func add(order: Order) async throws {
        try await OrderCommands.upsert(order, store: store)
    }

    func add(item: CartLineItem, lineItemId: String, to order: Order) {
        upsert(order: order.addingCartLineItem(item, lineItemId: lineItemId))
    }

    func updateStatus(of order: Order, with status: OrderStatus) {
        let store = store
        Task { try! await OrderCommands.updateStatus(status, of: order.documentId, executor: store) }
    }

    func addPayment(_ payment: Payment, paymentId: String, to order: Order) {
        let store = store
        Task { try! await OrderCommands.addPayment(payment, paymentId: paymentId, to: order.documentId, executor: store) }
    }

    func clearCart(of order: Order) {
        let store = store
        Task { try! await OrderCommands.clearCart(of: order, executor: store) }
    }

    // MARK: Eviction

    func runEvictionIfDue() async throws {
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
        _ = try await eviction.runIfDue()
    }

    // MARK: Helpers

    private func upsert(order: Order) {
        let store = store
        Task { try! await OrderCommands.upsert(order, store: store) }
    }
}

@MainActor private final class OrderPreparation {
    private let result = CurrentValueSubject<[Order]?, Never>(nil)
    private var task: Task<Void, Never>?

    init(orders: [Order], store: DittoStore) {
        task = Task {
            do {
                let prepared = try await SeedImageMigration.prepareOrders(orders, store: store)
                guard !Task.isCancelled else { return }
                result.send(prepared)
                result.send(completion: .finished)
            } catch {
                guard !Task.isCancelled else { return }
                preconditionFailure("Order preparation failed: \(error)")
            }
        }
    }

    var publisher: AnyPublisher<[Order], Never> {
        result.compactMap { $0 }
            .handleEvents(receiveCancel: { self.task?.cancel() })
            .eraseToAnyPublisher()
    }
}
