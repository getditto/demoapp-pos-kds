//
//  KDSViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

@MainActor class KDSViewModel: ObservableObject {
    @Published private(set) var orders = [Order]()
    @Published private(set) var isLoading = true
    private var cancellables = Set<AnyCancellable>()
    private let observation = VisibleObservation<String, [Order]>()
    private let ordersRepository: OrdersRepository
    private var locationId: String?
    private var isVisible = false

    init(ordersRepository: OrdersRepository, previewOrders: [Order]? = nil) {
        self.ordersRepository = ordersRepository
        if let previewOrders = previewOrders {
            self.orders = previewOrders
            isLoading = false
            return
        }

        ordersRepository.locationPublisher
            .removeDuplicates()
            .sink { [weak self] location in
                if self?.locationId != location {
                    self?.orders = []
                    self?.isLoading = true
                }
                self?.locationId = location
                self?.updateObservation()
            }
            .store(in: &cancellables)
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        orders = []
        isLoading = true
        updateObservation()
    }

    private func updateObservation() {
        observation.set(isVisible ? locationId : nil, observe: ordersRepository.observeLocationOrders) { [weak self] orders in
            self?.orders = KitchenOrders.select(from: orders)
            self?.isLoading = false
        }
    }
}
