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

class POS_VM: ObservableObject {
    static var shared = POS_VM()
    
    @Published private(set) var currentOrder: Order?
    @Published var saleItems: [SaleItem] = SaleItem.demoItems // demo collection for order display
    @Published var presentSelectLocationAlert = false
    private let dittoService = DittoService.shared
    private var cancellables = Set<AnyCancellable>()
    private var orderCancellable = AnyCancellable({})

    private init() {

        // use case: when Settings.useDemocLocations is true, the Locations tabView will display
        // a list of demo locations, allowing user to change between locations. This is the listener
        // for that change. We "reset" an unpaid outgoing order to clear it of sale items when
        // changing locations so that we're not leaving partial orders hanging on other devices'
        // KDS view.
        NotificationCenter.default.publisher(for: .willUpdateToLocationId)
            .sink {[weak self] locId in
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
            .sink {[weak self] loc in
                guard let loc = loc, let self = self else {
                    self?.currentOrder = nil
                    return
                }
                
                if let order = currentOrder, order.locationId == loc.id && !order.isPaid {
                    return
                }

                updateCurrentOrder()
            }
            .store(in: &cancellables)

        // Monitor changes in locationOrders for current location to update our published
        // currentOrder, which will cause appropriate UI changes in view subscribers.
        dittoService.$locationOrders
            .receive(on: DispatchQueue.main)
            .sink {[weak self] orders in
                guard let self = self else { return }
                // If empty docs array is passed, e.g. at first DittoService initialization,
                // theres nothing to do; return.
                guard orders.count > 0 else { return }

                // If the DittoService.currentLocationId hasn't been set yet (first launch, when
                // using demo locations), we can't create an order yet, so there's nothing to do here.
                guard let locId = dittoService.currentLocationId else {
                    print("POS_VM.dittoService.$locationOrders.sink: ERROR - NIL currentLocationId should not be possible here")
                    return
                }
                
                // If there is no currentOrder(.id) we won't be able to filter from docs to
                // update our published currentOrder, so return.
                guard let orderId = currentOrder?.id else { return }

                // Find an order matching currentOrder. This will be an update, e.g. added saleItem,
                // or a "reset" for X-Cancel-order button action
                if let order = orders.first(where: { $0.id == orderId && $0.locationId == locId }) {
                    currentOrder = order
                } else {
                    print("POS_VM.$locationOrders.sink: ERROR - matching doc not found for " +
                          "(docId:\(orderId), locId:\(locId))"
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    func addOrderItem(_ saleItem: SaleItem) {
        guard var curOrder = currentOrder else {
            print("Cannot add item: current order is NIL\n\n");
            return
        }
        
        let orderItem = OrderItem(saleItem: saleItem)
        // set order status to inProcess for every item added
        curOrder.status = .inProcess
        dittoService.add(item: orderItem, to: curOrder)
    }
        
    func payCurrentOrder() {
        guard let locId = dittoService.currentLocationId, let order = currentOrder else {
            print("POS_VM.\(#function): ERROR - either current Location or Order is nil --> return")
            return
        }
        let tx = Transaction.new(
            locationId: locId,
            orderId: order.id,
            amount: order.total
        )

        dittoService.updateOrderTransaction(order, with: tx)
        
        // pause a moment to show current order updated to PAID in POSOrderView
        // then create new order automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[weak self] in
            guard let self = self else { return }
            updateCurrentOrder()
        }
    }
    
    func updateCurrentOrder() {
        guard let locId = dittoService.currentLocationId else {
            print("POS_VM.\(#function): ERROR: unexpected dittoService.currentLocationId")
            return
        }
        orderCancellable = dittoService.incompleteOrderFuture()
            .receive(on: DispatchQueue.main)
            .sink {[weak self] optionalOrder in
                guard let self = self else { return }
                if let order = optionalOrder {
//                    print("POS_VM.\(#function).dittoService.restoredIncompleteOrder(...) FOUND recycled order")
                    currentOrder = order
                } else {
//                    print("POS_VM.\(#function).dittoService.restoredIncompleteOrder(...) ADD NEW order")
                    addNewCurrentOrder(for: locId)
                }
            }
    }

    func addNewCurrentOrder(for locId: String) {
        let order = newOrder(for: locId)
        currentOrder = order
        dittoService.add(order: order)
    }
    
    func newOrder(for locId: String) -> Order {
        let newOrder = Order.new(locationId: locId)
        return newOrder
    }
    
    func clearCurrentOrderSaleItemIds() {
        guard let order = currentOrder else {
            print("POS_VM.\(#function): ERROR: NIL currentOrder --> RETURN")
            return
        }
        // Note DittoService function side-effect sets status to .open
        dittoService.clearSaleItemIds(of: order)
    }
}
