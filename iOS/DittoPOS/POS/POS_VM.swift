//
//  POS_VM.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import SwiftUI

@MainActor class POS_VM: ObservableObject {
    static var shared = POS_VM()

    @Published private(set) var currentOrder: Order?
    @Published private(set) var saleItems: [SaleItem] = []
    @Published var presentSelectLocationAlert = false
    private let dittoService = DittoService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Sale items are now sourced from the synced sale_items collection,
        // filtered to the current location.
        dittoService.$locationSaleItems
            .receive(on: DispatchQueue.main)
            .assign(to: \.saleItems, on: self)
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .willUpdateToLocationId)
            .sink {[weak self] _ in
                guard let self = self else { return }
                guard let outgoingCurrentOrder = currentOrder,
                      !outgoingCurrentOrder.isPaid,
                      let _ = dittoService.currentLocation else {
                    return
                }
                dittoService.reset(order: outgoingCurrentOrder)
            }
            .store(in: &cancellables)

        dittoService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink {[weak self] location in
                guard let location = location, let self = self else {
                    self?.currentOrder = nil
                    return
                }

                if let order = currentOrder, order.documentId.locationId == location.id && !order.isPaid {
                    return
                }

                startNewOrder(for: location.id)
            }
            .store(in: &cancellables)

        // Refresh the local copy of the current order whenever the synced
        // collection changes. The synced version may have updates from another
        // device, so we look up our order by id and re-bind to it.
        dittoService.$locationOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                guard let self,
                      let orderId = currentOrder?.documentId.id,
                      let locationId = dittoService.currentLocationId else { return }
                currentOrder = orders.first { $0.documentId.id == orderId && $0.documentId.locationId == locationId }
            }
            .store(in: &cancellables)
    }

    func addOrderItem(_ saleItem: SaleItem) {
        guard let order = currentOrder else { return }
        dittoService.add(
            item: CartLineItem(from: saleItem),
            lineItemId: CartLineItem.newLineItemId(),
            to: order
        )
    }

    func payCurrentOrder() {
        guard let order = currentOrder else { return }
        let payment = Payment(type: .cash, amount: order.total, status: .complete)
        dittoService.addPayment(payment, paymentId: Payment.newPaymentId(), to: order)

        // Brief pause so the paid state is visible, then start a fresh order.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, let locationId = dittoService.currentLocationId else { return }
            startNewOrder(for: locationId)
        }
    }

    func clearCurrentOrderCart() {
        guard let order = currentOrder else { return }
        dittoService.clearCart(of: order)
    }

    private func startNewOrder(for locationId: String) {
        let order = Order.new(locationId: locationId)
        currentOrder = order
        dittoService.add(order: order)
    }
}
