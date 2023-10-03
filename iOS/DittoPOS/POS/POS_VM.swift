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
    @Published private(set) var currentOrder: Order?
    @Published var saleItems: [SaleItem] = SaleItem.demoItems // demo collection for order display
    private var cancellables = Set<AnyCancellable>()
    private let dittoService = DittoService.shared
    
    static var shared = POS_VM()
    
    private var deviceId: String {
        dittoService.deviceId
    }

    private init() {
        // Try to restore an order from UserDefaults before $currentLocation fires
        if let previousOrder = dittoService.restoredIncompleteOrder(for: nil) {
            currentOrder = previousOrder
        }
        
        // Reset an outgoing unpaid currentOrder when locationId changes. This will prevent a
        // lingering incomplete order in the KDS view of other devices, which would be only
        // recovered and cleaned up below in $currentLocation.sink via restoredIncompleteOrder
        // when switching back to that location, or left lingering if not returning.
        NotificationCenter.default.publisher(for: .willUpdateToLocationId)
            .sink {[weak self] locId in
                guard let self = self else { return }
                guard let outgoingCurrentOrder = currentOrder,
                      !outgoingCurrentOrder.isPaid,
                      let _ = dittoService.currentLocation else { return }

//                print("POS_VM.Notification.willUpdateToLocationId.sink: CALL to reset OUTGOING currentOrder for \(outgoingLoc.name)")
                dittoService.resetOrderDoc(for: outgoingCurrentOrder)
            }
            .store(in: &cancellables)
        
        dittoService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink {[weak self] loc in
                guard let loc = loc, let self = self else { return }

                if let order = currentOrder,
                   order.locationId == loc.id && !order.isPaid {
//                        print("POS_VM.$currentLocation.sink: CURRENT ORDER VALIDATED --> RETURN")
                        return
                    }
                
                // Try to restore an incomplete order for the incoming current location and set
                // it as the currentOrder and return. If there is none, execution will continue
                // and a new order will be added and set below.
                if let restoredOrder = dittoService.restoredIncompleteOrder(for: loc.id) {
//                    print("POS_VM.$currentLocation.sink: SET RECYCLED ORDER --> RETURN")
                    currentOrder = restoredOrder
                    return
                }

//                print("POS_VM.$currentLocation.sink: CALL addNewCurrentOrder()")
                addNewCurrentOrder(for: loc.id)
            }
            .store(in: &cancellables)

        // Monitor changes in docs for current location, published from DittoService, to update
        // our published currentOrder, which will cause appropriate UI changes in subscribers.
        dittoService.$locationOrderDocs
            .receive(on: DispatchQueue.main)
            .sink {[weak self] docs in
                guard let self = self else { return }
                // If empty docs array is passed, e.g. at first DittoService initialization,
                // theres nothing to do; return.
                guard docs.count > 0 else { return }
                
                // If the DittoService.currentLocationId hasn't been set yet (first launch), we can't
                // create an order yet, so there's nothing to do here. Actually, I don't think this
                // should be able to happen. The docs collection is from a location-based query. Well
                // I suppose it's possible that for a location change DittoService could update the
                // query (with the new location) which could fire this sink before the currentLocation
                // publisher is updated... mm... well no, the dittoService.currentLocationId is
                // updated first, so it should not be possible for locationOrderDocs to be
                // updated without a currentLocationId - unless there's a race condition, so we
                // should use the guard to check expectations.
                guard let locId = dittoService.currentLocationId else {
                    print("POS_VM.dittoService.$locationDocs.sink: ERROR - NIL currentLocationId should not be possible here")
                    return
                }
                
                // If there is no currentOrder(.id) we won't be able to filter from docs to
                // update our published currentOrder, so return.
                guard let docId = currentOrder?.id else { return }

                // Create DittoDocumentID with currentOrder.id, filter for this ID, then initialize
                // and update published currentOrder object.
                let docID = Order.docId(docId, locId)
                if let dbDoc = docs.first(where: { $0.id == docID }) {
                    // Last case: should be an order item update - set as currentOrder
                    currentOrder = Order(doc: dbDoc)
                } else {
                    print("POS_VM.$locationOrderDocs.sink: ERROR - matching doc not found for " +
                          "(docId:\(docId), locId:\(locId))"
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    func addOrderItem(_ saleItem: SaleItem) {
        //TODO: alert user to select location
        guard var curOrder = currentOrder else {
            print("Cannot add item: current order is NIL\n\n");
            return
        }
        
        let orderItem = OrderItem(saleItem: saleItem)
        // set order status to inProcess for every item added
        curOrder.status = .inProcess
        dittoService.addItemToOrder(item: orderItem, order: curOrder)
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
                // 1st try to recycle
                if let restoredOrder = dittoService.restoredIncompleteOrder(for: order.locationId) {
//                    print("POS_VM.\(#function): ORDER PAID - SET RECYCLED ORDER --> RETURN")
                    currentOrder = restoredOrder
                    return
                }

//                print("POS_VM.\(#function): ORDER PAID - CALL to create/add NEW ORDER")
                addNewCurrentOrder(for: locId)
            }
    }
    
    func addNewCurrentOrder(for locId: String) {
        let order = newOrder(for: locId)
        currentOrder = order
        dittoService.addOrder(order)
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
        // Note DS function side-effect sets status to .open
        dittoService.clearOrderSaleItemIds(order)
    }
}
