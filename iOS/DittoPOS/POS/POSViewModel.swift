//
//  POSViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import SwiftUI

@MainActor class POSViewModel: ObservableObject {

    @Published private(set) var currentOrder: Order?
    @Published private(set) var saleItems: [SaleItem] = []

    // MARK: Derived UI state

    var orderTitle: String {
        "Order #\(currentOrder?.title ?? "...")"
    }

    var orderItems: [(id: String, item: CartLineItem)] {
        guard let order = currentOrder else { return [] }
        return order.cart
            .sorted { $0.value.createdAt < $1.value.createdAt }
            .map { (id: $0.key, item: $0.value) }
    }

    var orderTotalDisplay: String { (currentOrder?.total ?? Price(cents: 0)).description }
    var orderIsPaid: Bool { currentOrder?.isPaid ?? false }
    var orderIsEmpty: Bool { currentOrder?.cart.isEmpty ?? true }
    var actionsDisabled: Bool { orderIsPaid || orderIsEmpty }
    var payButtonLabel: String { orderIsPaid ? "Paid" : "Pay" }

    /// What the order list needs to auto-scroll to the bottom: the id of the
    /// trailing line item and the animation delay (the delay only matters
    /// during landscape rotation when the keyboard is settling). Returns nil
    /// when the device is in a transitional orientation — in that case the
    /// view should skip the scroll.
    func scrollToBottomConfig() -> (id: String, delay: TimeInterval)? {
        let orientation = UIDevice.current.orientation
        guard orientation.isLandscape || orientation.isPortrait else { return nil }

        guard let last = orderItems.last?.id else { return nil }

        let needsDelay = UIScreen.isPortrait
            && UIDevice.current.orientation.isLandscape
            && orderItems.count > 4
        return (last, needsDelay ? 0.5 : 0.0)
    }

    private let ordersRepository: OrdersRepository
    private let saleItemsRepository: SaleItemsRepository
    private let locationsRepository: LocationsRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        ordersRepository: OrdersRepository,
        saleItemsRepository: SaleItemsRepository,
        locationsRepository: LocationsRepository
    ) {
        self.ordersRepository = ordersRepository
        self.saleItemsRepository = saleItemsRepository
        self.locationsRepository = locationsRepository

        // Menu items follow the active location.
        saleItemsRepository.$locationSaleItems
            .receive(on: DispatchQueue.main)
            .assign(to: &$saleItems)

        // On location change: reset any unpaid order left at the previous
        // location, then start a fresh order at the new one (or clear when
        // cleared). `scan` pairs consecutive emissions so we can read both
        // the outgoing and incoming location in one place.
        locationsRepository.$currentLocation
            .scan((nil, nil)) { acc, next -> (Location?, Location?) in
                (acc.1, next)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] previous, current in
                guard let self else { return }

                if let previous,
                   let outgoing = currentOrder,
                   !outgoing.isPaid,
                   outgoing.documentId.locationId == previous.id,
                   previous.id != current?.id {
                    ordersRepository.reset(order: outgoing)
                }

                guard let current else {
                    currentOrder = nil
                    return
                }

                if let order = currentOrder, order.documentId.locationId == current.id, !order.isPaid {
                    return
                }

                startNewOrder(for: current.id)
            }
            .store(in: &cancellables)

        // Re-bind the current order to the synced version on every emission.
        // Only assign when we find a match — right after `startNewOrder`
        // writes a doc, the observer hasn't round-tripped yet and the new id
        // isn't in `locationOrders`, so a nil assignment would clobber it.
        ordersRepository.$locationOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                guard let self,
                      let orderId = currentOrder?.documentId.id,
                      let locationId = locationsRepository.currentLocationId,
                      let match = orders.first(where: {
                          $0.documentId.id == orderId && $0.documentId.locationId == locationId
                      })
                else { return }
                currentOrder = match
            }
            .store(in: &cancellables)
    }

    func addOrderItem(_ saleItem: SaleItem) {
        guard let order = currentOrder else { return }
        ordersRepository.add(
            item: CartLineItem(from: saleItem),
            lineItemId: CartLineItem.newLineItemId(),
            to: order
        )
    }

    func payCurrentOrder() {
        guard let order = currentOrder else { return }
        let payment = Payment(type: .cash, amount: order.total, status: .complete)
        ordersRepository.addPayment(payment, paymentId: Payment.newPaymentId(), to: order)

        // Brief pause so the paid state is visible, then start a fresh order.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, let locationId = locationsRepository.currentLocationId else { return }
            startNewOrder(for: locationId)
        }
    }

    func clearCurrentOrderCart() {
        guard let order = currentOrder else { return }
        ordersRepository.clearCart(of: order)
    }

    private func startNewOrder(for locationId: String) {
        let order = Order.new(locationId: locationId)
        currentOrder = order
        ordersRepository.add(order: order)
    }
}
