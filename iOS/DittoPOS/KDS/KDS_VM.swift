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
class KDS_VM: ObservableObject {
    @Published private(set) var orders = [Order]()    
    private let dittoService = DittoService.shared
    private var orderDocsCancellable = AnyCancellable({})
    private var cancellables = Set<AnyCancellable>()

    init() {
        dittoService.$locationOrders
            .sink {[weak self ] orders in
                guard let self = self else { return }

                let filteredOrders = orders.filter {
                    $0.status.rawValue == OrderStatus.inProcess.rawValue ||
                    $0.status.rawValue == OrderStatus.processed.rawValue
                }
                let sortedOrders = filteredOrders.sorted { (lhs, rhs) in
                    if lhs.status == rhs.status {
                        return lhs.createdOn > rhs.createdOn
                    }
                    return lhs.status.rawValue < rhs.status.rawValue
                }

                self.orders = sortedOrders
            }
            .store(in: &cancellables)
    }
}

