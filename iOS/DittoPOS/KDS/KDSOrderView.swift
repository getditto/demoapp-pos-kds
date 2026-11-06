//
//  KDSOrderView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import SwiftUI

struct KDSOrderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let ordersRepository: OrdersRepository
    let order: Order

    init(_ order: Order, ordersRepository: OrdersRepository) {
        self.order = order
        self.ordersRepository = ordersRepository
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(DateFormatter.shortTime.string(from: order.createdAt)) #\(order.title)")
                .padding(4)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)
                .border(order.status.color, width: 2)

            ForEach(order.summary.sorted(by: <), id: \.key) { key, value in
                divider()
                KDSOrderItemView(title: key, count: value)
            }

            HStack(spacing: 0) {
                Spacer()
                if order.isPaid {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.black)
                        .padding(2)
                }
            }
            .frame(height: 35)
            .frame(maxWidth: .infinity)
            .background(order.status.color)
        }
        .padding(4)
        .onTapGesture {
            if let next = order.status.next {
                ordersRepository.updateStatus(of: order, with: next)
            }
        }
    }
}
