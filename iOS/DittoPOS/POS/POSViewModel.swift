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

    // Rotation must settle before scrolling an order alongside the keyboard.
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
    private let locationId: () -> String?
    private let catalogObservation = VisibleObservation<String, [SaleItem]>()
    private let orderObservation = VisibleObservation<DocumentID, Order?>()
    private var isVisible = false
    private var observedLocation: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        ordersRepository: OrdersRepository,
        saleItemsRepository: SaleItemsRepository,
        locationPublisher: AnyPublisher<Location?, Never>,
        locationId: @escaping () -> String?
    ) {
        self.ordersRepository = ordersRepository
        self.saleItemsRepository = saleItemsRepository
        self.locationId = locationId

        // An unpaid cart belongs to its original location.
        locationPublisher
            .removeDuplicates { $0?.id == $1?.id }
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
                    updateObservations()
                    return
                }

                if let order = currentOrder, order.documentId.locationId == current.id, !order.isPaid {
                    return
                }

                startNewOrder(for: current.id)
            }
            .store(in: &cancellables)

    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        updateObservations()
    }

    private func updateObservations() {
        let activeLocation = isVisible ? locationId() : nil
        if observedLocation != activeLocation {
            saleItems = []
            observedLocation = activeLocation
        }
        catalogObservation.set(activeLocation, observe: saleItemsRepository.observeLocationSaleItems) { [weak self] items in
            self?.saleItems = items
        }
        let id = currentOrder?.documentId
        orderObservation.set(activeLocation == id?.locationId ? id : nil, observe: ordersRepository.observeOrder) { [weak self] order in
            // A newly inserted document may not be in the first callback yet.
            guard let self, let order,
                  let matched = OrderSelection.observedOrder(id: currentOrder?.documentId.id, locationId: locationId(), in: [order])
            else { return }
            currentOrder = matched
        }
    }

    func addOrderItem(_ saleItem: SaleItem) {
        guard let order = currentOrder,
              order.documentId.locationId == locationId(),
              saleItem.documentId.locationId == order.documentId.locationId
        else { return }
        ordersRepository.add(
            item: CartLineItem(from: saleItem),
            lineItemId: CartLineItem.newLineItemId(),
            to: order
        )
    }

    func payCurrentOrder() {
        guard let order = currentOrder, order.documentId.locationId == locationId() else { return }
        let payment = Payment(type: .cash, amount: order.total, status: .complete)
        ordersRepository.addPayment(payment, paymentId: Payment.newPaymentId(), to: order)

        // Brief pause so the paid state is visible, then start a fresh order.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, let locationId = locationId() else { return }
            startNewOrder(for: locationId)
        }
    }

    func clearCurrentOrderCart() {
        guard let order = currentOrder, order.documentId.locationId == locationId() else { return }
        ordersRepository.clearCart(of: order)
    }

    private func startNewOrder(for locationId: String) {
        let order = Order.new(locationId: locationId)
        currentOrder = order
        ordersRepository.add(order: order)
        updateObservations()
    }
}
