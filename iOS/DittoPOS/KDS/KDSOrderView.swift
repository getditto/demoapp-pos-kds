//
//  KDSOrderView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Combine
import SwiftUI

@MainActor class KDSOrderViewModel: ObservableObject {
    @Published var order: Order
    private let ordersRepository: OrdersRepository
    private var cancellables = Set<AnyCancellable>()

    init(_ order: Order, ordersRepository: OrdersRepository) {
        self.order = order
        self.ordersRepository = ordersRepository

        ordersRepository.orderPublisher(order)
            .filter { $0.status == .inProcess || $0.status == .processed }
            .sink { [weak self] updatedOrder in
                self?.order = updatedOrder
            }
            .store(in: &cancellables)
    }

    // MARK: Derived UI state

    var titleText: String { order.title }
    var timestampText: String { DateFormatter.shortTime.string(from: order.createdAt) }
    var headerText: String { "\(timestampText) #\(titleText)" }
    var statusColor: Color { order.status.color }
    var statusTitle: String { order.status.title }
    var summaryEntries: [(key: String, value: Int)] { order.summary.sorted(by: <) }
    var isPaid: Bool { order.isPaid }

    func incrementOrderStatus() {
        guard let next = order.status.next else { return }
        ordersRepository.updateStatus(of: order, with: next)
    }
}

struct KDSOrderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: KDSOrderViewModel

    init(_ order: Order, ordersRepository: OrdersRepository) {
        self._viewModel = StateObject(wrappedValue: KDSOrderViewModel(order, ordersRepository: ordersRepository))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.headerText)
                .padding(4)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)
                .border(viewModel.statusColor, width: 2)

            ForEach(viewModel.summaryEntries, id: \.key) { key, value in
                divider()
                KDSOrderItemView(title: key, count: value)
            }

            HStack(spacing: 0) {
                Spacer()
                if viewModel.isPaid {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.black)
                        .padding(2)
                }
            }
            .frame(height: 35)
            .frame(maxWidth: .infinity)
            .background(viewModel.statusColor)
        }
        .padding(4)
        .onTapGesture {
            viewModel.incrementOrderStatus()
        }
    }
}
