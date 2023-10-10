///
//  KDSOrderView.swift
//  DittoPOS
//
//  Created by Eric Turner on 8/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

class KDSOrderVM: ObservableObject {
    @Published var order: Order
    @Published var orderItems = OrderItemsSummary()//[String:Int]
    private var cancelleables = Set<AnyCancellable>()
        
    init(_ order: Order) {
        self.order = order
        
        DittoService.shared.orderPublisher(order)
            .filter( {$0.status == .inProcess || $0.status == .processed} )
            .sink {[weak self] updatedOrder in
                self?.order = updatedOrder
                self?.orderItems = order.summary
            }
            .store(in: &cancelleables)
    }
    
    func incrementOrderStatus() {
        let newStatus = OrderStatus(rawValue: order.status.rawValue + 1)!
        DittoService.shared.updateOrderStatus(order, with: newStatus)
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
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .background(vm.order.status.color)
        }
        .padding(4)
        .onTapGesture {
            vm.incrementOrderStatus()
        }
    }

    var titleText: String {
        "\(vm.order.title)"
    }
    var timestampText: String {
        "\(DateFormatter.shortTime.string(from: vm.order.createdOn))"
    }
}

struct KDSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrderView(Order.preview())
    }
}
