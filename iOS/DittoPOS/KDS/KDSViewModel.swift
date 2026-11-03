//
//  KDSViewModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

/// Supplies published orders array to OrdersGridView
@MainActor class KDSViewModel: ObservableObject {
    @Published private(set) var orders = [Order]()
    private var cancellables = Set<AnyCancellable>()

    init(ordersRepository: OrdersRepository, previewOrders: [Order]? = nil) {
        if let previewOrders = previewOrders {
            self.orders = previewOrders
            return
        }

        ordersRepository.$locationOrders
            .sink { [weak self] orders in
                guard let self else { return }

                self.orders = KitchenOrders.select(from: orders)
            }
            .store(in: &cancellables)
    }
}
