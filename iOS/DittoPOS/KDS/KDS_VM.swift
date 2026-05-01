///
//  KDS_VM.swift
//  DittoPOS
//
//  Created by Eric Turner on 8/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import Foundation

/// Supplies published orders array to OrdersGridView
@MainActor class KDS_VM: ObservableObject {
    @Published private(set) var orders = [Order]()
    private let dittoService = DittoService.shared
    private var cancellables = Set<AnyCancellable>()

    init(previewOrders: [Order]? = nil) {
        if let previewOrders = previewOrders {
            self.orders = previewOrders
            return
        }

        dittoService.$locationOrders
            .sink {[weak self] orders in
                guard let self = self else { return }

                let filtered = orders.filter {
                    $0.status == .inProcess || $0.status == .processed
                }
                let sorted = filtered.sorted { lhs, rhs in
                    if lhs.status == rhs.status {
                        return lhs.createdOn > rhs.createdOn
                    }
                    return lhs.status.rank < rhs.status.rank
                }

                self.orders = sorted
            }
            .store(in: &cancellables)
    }
}
