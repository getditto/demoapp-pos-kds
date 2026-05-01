///
//  KDSOrderView.swift
//  DittoPOS
//
//  Created by Eric Turner on 8/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

@MainActor class KDSOrderVM: ObservableObject {
    @Published var order: Order
    private var cancellables = Set<AnyCancellable>()

    init(_ order: Order) {
        self.order = order

        DittoService.shared.orderPublisher(order)
            .filter { $0.status == .inProcess || $0.status == .processed }
            .sink {[weak self] updatedOrder in
                self?.order = updatedOrder
            }
            .store(in: &cancellables)
    }

    func incrementOrderStatus() {
        guard let next = order.status.next else { return }
        DittoService.shared.updateStatus(of: order, with: next)
    }
}

struct KDSOrderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm: KDSOrderVM

    init(_ order: Order) {
        self._vm = StateObject(wrappedValue: KDSOrderVM(order))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(timestampText) #\(titleText)")
                .padding(4)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)
                .border(vm.order.status.color, width: 2)

            ForEach(vm.order.summary.sorted(by: <), id: \.key) { key, value in
                divider()
                KDSOrderItemView(title: key, count: value)
            }

            HStack(spacing: 0) {
                Spacer()
                if vm.order.isPaid {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.black)
                        .padding(2)
                }
            }
            .frame(height: 35)
            .frame(maxWidth: .infinity)
            .background(vm.order.status.color)
            #if os(tvOS)
            Spacer()
            Button(action: {
                vm.incrementOrderStatus()
            }, label: {
                Text("clear \(vm.order.status.title)")
                    .font(.caption)
            })
            .padding(.horizontal)
            #endif
        }
        .padding(4)
        .onTapGesture {
            vm.incrementOrderStatus()
        }
    }

    var titleText: String { vm.order.title }
    var timestampText: String {
        DateFormatter.shortTime.string(from: vm.order.createdOn)
    }
}

struct KDSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrderView(Order.preview())
    }
}
