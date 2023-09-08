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
    @Published var orders = [Order]()
    
    private let dittoService = DittoService.shared
    private var orderDocsCancellable = AnyCancellable({})
    private var cancellables = Set<AnyCancellable>()

    init() {
        dittoService.$locationOrderDocs
            .sink {[weak self ] docs in
                guard let self = self else { return }
//                print("KDS_VM.$locationOrderDocs --> in with count \(docs.count)")
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
//                print("KDS_VM.$locationOrderDocs: update with \(docs.count) docs")
                orders = sortedOrders
            }
            .store(in: &cancellables)
    }
}

