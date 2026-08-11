//
//  KDSView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct KDSView: View {
    let ordersRepository: OrdersRepository

    init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
    }

    var body: some View {
        KDSOrdersGridView(ordersRepository: ordersRepository)
    }
}
