///
//  DataViewModel.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

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
            .map { $0.sorted { $0.name < $1.name } }
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

                if let order = currentOrder, order.locationId == location.id && !order.isPaid {
                    return
                }

                startNewOrder(for: location.id)
            }
            .store(in: &cancellables)

        dittoService.$locationOrders
            .receive(on: DispatchQueue.main)
            .sink {[weak self] orders in
                guard let self = self else { return }
                guard orders.count > 0 else { return }
                guard let locationId = dittoService.currentLocationId else {
                    print("POS_VM.dittoService.$locationOrders.sink: ERROR - NIL currentLocationId")
                    return
                }
                guard let orderId = currentOrder?.id else { return }

                if let order = orders.first(where: { $0.id == orderId && $0.locationId == locationId }) {
                    currentOrder = order
                } else {
                    print("POS_VM.$locationOrders.sink: ERROR - matching doc not found for "
                          + "(docId:\(orderId), locationId:\(locationId))")
                }
            }
            .store(in: &cancellables)
    }

    func addOrderItem(_ saleItem: SaleItem) {
        guard let curOrder = currentOrder else {
            print("Cannot add item: current order is NIL")
            return
        }
        let lineItem = CartLineItem(from: saleItem)
        let lineItemId = CartLineItem.newLineItemId()
        dittoService.add(item: lineItem, lineItemId: lineItemId, to: curOrder)
    }

    func payCurrentOrder() {
        guard let order = currentOrder else {
            print("POS_VM.\(#function): ERROR - current order is nil")
            return
        }
        let payment = Payment(
            type: .cash,
            amount: order.total,
            status: .complete
        )
        let paymentId = Payment.newPaymentId()
        dittoService.addPayment(payment, paymentId: paymentId, to: order)

        // pause briefly to show paid state, then create new order automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[weak self] in
            guard let self = self,
                  let locationId = dittoService.currentLocationId else { return }
            startNewOrder(for: locationId)
        }
    }

    private func startNewOrder(for locationId: String) {
        let order = Order.new(locationId: locationId)
        currentOrder = order
        dittoService.add(order: order)
    }

    func clearCurrentOrderCart() {
        guard let order = currentOrder else {
            print("POS_VM.\(#function): ERROR: NIL currentOrder")
            return
        }
        dittoService.clearCart(of: order)
    }
}
