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
//    @Published var selectedTab: TabViews = .locations
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
        if let previousOrder = restoredIncompleteOrder(for: nil) {
            currentOrder = previousOrder
        }
                
        dittoService.$currentLocation
            .sink {[weak self] loc in
                guard let loc = loc else {
                    print("POS_VM.$currentLocation.sink: NIL currentLocation --> RETURN")
                    return
                }
//                print("POS_VM.$currentLocation.sink: fired with \(loc.name)")

                if let order = self?.currentOrder,
                   order.locationId == loc.id && !order.isPaid {
                        print("POS_VM.$currentLocation.sink: CURRENT ORDER VALIDATED --> RETURN")
                        return
                    }
                
                // Try to restore an incomplete order for the current location and set
                // it as the currentOrder and return. If there is none, execution will fall
                // through and a new order will be added and set.
                if let restoredOrder = self?.restoredIncompleteOrder(for: loc.id) {
                    print("POS_VM.$currentLocation.sink: SET RECYCLED ORDER --> RETURN")
                    self?.currentOrder = restoredOrder
                    return
                }

                print("POS_VM.$currentLocation.sink: CALL addNewCurrentOrder()")
                self?.addNewCurrentOrder(for: loc.id)
            }
            .store(in: &cancellables)

        // Monitor changes in docs for current location, published from DittoService, to update
        // our published currentOrder, which will cause appropriate UI changes in subscribers.
        dittoService.$locationOrderDocs
            .sink {[weak self] docs in
                guard let self = self else { print("POS_VM.$locationOrderDocs.sink:  NO SELF --> RETURN"); return }
                
//                print("POS_VM.$locationOrderDocs.sink --> in")
//                print("POS_VM.$locationOrderDocs.sink: docs.count: \(docs.count)")
                
                // If empty [DittoDocument] value comes through, e.g. at first DittoService initialization,
                // theres nothing to do; return.
                guard docs.count > 0 else {
                    print("POS_VM.dittoService.$locationDocs.sink - fired with 0 docs for this location --> RETURN")
                    return
                }
                // If the DittoService.currentLocationId hasn't been set yet (first launch), we can't
                // create an order yet, so there's nothing to do here. Actually, I don't think this
                // should be able to happen. The docs collection is from a location-based query. Well
                // I suppose it's possible that for a location change DittoService could update the
                // query (with the new location) which could fire this sink before the currentLocation
                // publisher is updated... mm... well no, the dittoService.currentLocationId is
                // updated first, so it should not be possible for locationOrderDocs to be
                // updated without a currentLocationId. Still it's an optional so we should use
                // the guard to check expectations, as we have here.
                guard let locId = dittoService.currentLocationId else {
                    print("POS_VM.dittoService.$locationDocs.sink: ERROR - NIL currentLocationId should not be possible here")
                    return
                }
                
                // If there is no currentOrder(.id) we won't be able to filter from docs to
                // update our published currentOrder, so return.
                guard let docId = currentOrder?.id else {
                    print("POS_VM.$locationOrderDocs.sink: no currentOrder --> return")
                    return
                }

                // Create DittoDocumentID with currentOrder.id, filter for this ID, then initialize
                // and update published currentOrder object.
                let docID = Order.docId(docId, locId)
                if let dbDoc = docs.first(where: { $0.id == docID }) {
                    // Last case: should be an order item update - set as currentOrder
//                    print("POS_VM.$locationOrderDocs.sink: SET currentOrder from UPDATED dbDoc")
                    currentOrder = Order(doc: dbDoc)
                } else {
                    print("POS_VM.$locationOrderDocs.sink: ERROR(?) - matching doc not found for " +
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
//        print("POS_VM.\(#function): orderItem --> IN: \(orderItem.id)")
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
            // wait a moment to show current order updated to PAID
            // then create new order automatically
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[weak self] in
                print("POS_VM.\(#function): ORDER PAID - CALL to create/add NEW ORDER")
                self?.addNewCurrentOrder(for: locId)
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
            print("POS_VM.\(#function): NIL currentOrder --> RETURN")
            return
        }
        // Note DS function side-effect sets status to .open
        dittoService.clearOrderSaleItemIds(order)
    }

    func restoredIncompleteOrder(for locId: String?) -> Order? {
        guard let locId = locId ?? UserDefaults.standard.storedLocationId else {
            print("POS_VM.\(#function): storeLocationId is NIL --> RETURN")
            return nil
        }
        
        let incompleteOrderDocs = dittoService.orderDocs.find(
            "_id.locationId == '\(locId)' && deviceId == '\(deviceId)' && length(keys(transactionIds)) == 0"
        ).exec().sorted(by: { $0["createdOn"].stringValue < $1["createdOn"].stringValue })

        print("POS_VM.\(#function): incompleteOrderDocs.count: \(incompleteOrderDocs.count)")
        
        if let incompleteOrderDoc = incompleteOrderDocs.first {
            print("POS_VM.\(#function): FOUND INCOMPLETE ORDER --> RETURN")
            let order = Order(doc: incompleteOrderDoc)
            updateOrderCreatedDate(order)
            return order
        }
        
//        print("POS_VM.\(#function): RETURN --> refurbishedEmptyOrder()")
//        return refurbishedEmptyOrder(for: locId)
        print("POS_VM.\(#function): RETURN --> NIL")
        return nil
    }

    /*
    // I think this only ever fires on launch, before location is set:
    // wouldn't this be superceded by restoredIncompleteOrder() above? where we look for incomplete
    // orders regardless of status? Or if we need at some point to consider status we could add
    // that filtering to the restoredIncompleteOrder()... leaving in with a breakpoint for now
    func refurbishedEmptyOrder(for locId: String) -> Order? {
        // call DS to search for order-for-loc where status is .open and reset createdAt timestamp
        let emptyOrderDocs = dittoService.orderDocs.find(
            "_id.locationId == '\(locId)' " +
            "&& deviceId == '\(deviceId)' " +
            "&& status == \(OrderStatus.open.rawValue)"
        ).exec()
        if let gotOne = emptyOrderDocs.first {
            print("POS_VM.\(#function): FOUND reusable open order: \(gotOne).createdOn \(gotOne["createdOn"].stringValue)")
            var refurbOrder = Order(doc: gotOne)
            refurbOrder.createdOn = Date()

            updateOrderCreatedDate(refurbOrder)
            return refurbOrder
        }
        return nil
    }
     */
    
    func updateOrderCreatedDate(_ order: Order, date: Date = Date()) {
        dittoService.orderDocs.findByID(order.id).update {mutableDoc in
            let newDateStr = DateFormatter.isoDate.string(from: date)
            print("POS_VM.\(#function): UPDATE reusableDoc.createdOn: \(newDateStr)")
            mutableDoc?["createdOn"].set(newDateStr)
        }
    }
}
