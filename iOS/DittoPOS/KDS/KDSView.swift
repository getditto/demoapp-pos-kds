//
//  KDSView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct KDSView: View {
    let ordersRepository: OrdersRepository
    let isActive: Bool

    init(ordersRepository: OrdersRepository, isActive: Bool = true) {
        self.ordersRepository = ordersRepository
        self.isActive = isActive
    }

    var body: some View {
        KDSOrdersGridView(ordersRepository: ordersRepository, isActive: isActive)
    }
}
