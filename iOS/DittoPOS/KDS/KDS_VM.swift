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

    init(previewOrders: [Order]? = nil) {
        if let previewOrders {
            orders = previewOrders
            return
        }

        dittoService.$locationOrderDocs
            .sink {[weak self ] docs in
                guard let self = self else { return }

                let filteredDocs = docs.filter {
                    $0["status"].intValue == OrderStatus.inProcess.rawValue ||
                    $0["status"].intValue == OrderStatus.processed.rawValue
                }
                let updatedOrders = filteredDocs.map { Order(doc: $0) }
                let sortedOrders = updatedOrders.sorted { (lhs, rhs) in
                    if lhs.status == rhs.status {
                        return lhs.createdOn > rhs.createdOn
                    }
                    return lhs.status.rawValue < rhs.status.rawValue
                }

                orders = sortedOrders
            }
            .store(in: &cancellables)
    }
}

