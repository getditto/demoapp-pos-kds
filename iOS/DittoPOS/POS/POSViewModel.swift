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
    @Published private(set) var isCatalogLoading = true
    var isLoading: Bool { isCatalogLoading || currentOrder == nil }

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
    private var selectedOrderId: DocumentID?
    private var newOrderTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        ordersRepository: OrdersRepository,
        saleItemsRepository: SaleItemsRepository,
        locationPublisher: AnyPublisher<String?, Never>,
        locationId: @escaping () -> String?
    ) {
        self.ordersRepository = ordersRepository
        self.saleItemsRepository = saleItemsRepository
        self.locationId = locationId

        locationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                guard let self, current == locationId() else { return }
                if let current {
                    startNewOrder(for: current)
                } else {
                    newOrderTask?.cancel()
                    selectedOrderId = nil
                    currentOrder = nil
                    updateObservations()
                }
            }
            .store(in: &cancellables)

    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        currentOrder = nil
        updateObservations()
    }

    private func updateObservations() {
        let selectedLocation = locationId()
        let activeLocation = isVisible ? selectedLocation : nil
        if observedLocation != activeLocation {
            saleItems = []
            isCatalogLoading = true
            observedLocation = activeLocation
        }
        catalogObservation.set(activeLocation, observe: saleItemsRepository.observeLocationSaleItems) { [weak self] items in
            self?.saleItems = items
            self?.isCatalogLoading = false
        }
        let id = selectedOrderId
        orderObservation.set(activeLocation == id?.locationId ? id : nil, observe: ordersRepository.observeOrder) { [weak self] order in
            guard let self else { return }
            guard let order else {
                if let locationId = locationId() { startNewOrder(for: locationId) }
                return
            }
            guard let matched = OrderSelection.observedOrder(id: selectedOrderId?.id, locationId: locationId(), in: [order])
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
        newOrderTask?.cancel()
        selectedOrderId = nil
        currentOrder = nil
        updateObservations()
        let order = Order.new(locationId: locationId)
        newOrderTask = Task { [weak self] in
            guard let self else { return }
            try! await ordersRepository.add(order: order)
            guard !Task.isCancelled, locationId == self.locationId() else { return }
            selectedOrderId = order.documentId
            updateObservations()
        }
    }
}
