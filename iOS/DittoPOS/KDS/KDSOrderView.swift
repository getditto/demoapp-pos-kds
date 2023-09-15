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
//                print("KDSOrderViewVM.$orderPublisher --> ORDER UPDATED: \(updatedOrder)")
                self?.order = updatedOrder
//                print("KDSOrderViewVM.$orderPublisher --> ORDER UPDATED with items.summary: \(order.summary.count)")
                self?.orderItems = order.summary
            }
            .store(in: &cancelleables)
    }
    
    func incrementOrderStatus() {
        let newStatus = OrderStatus(rawValue: order.status.rawValue + 1)!
//        print("KDSOrderViewVM.\(#function): increment order.\(order.status.title) to \(newStatus.title)")
        DittoService.shared.updateOrderStatus(order, with: newStatus)
    }
}

struct KDSOrderView: View {
    @StateObject var vm: KDSOrderVM
    
    init(_ order: Order) {
        self._vm = StateObject(wrappedValue: KDSOrderVM(order))
//        print("KDSOrderView.init() --> order.items: \(order.orderItems.count)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(timestampText) | \(titleText)")
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
                    Group {
                        Image(systemName: "dollarsign")
                        Image(systemName: "dollarsign")
                    }
                    .foregroundColor(.yellow)
                    .padding(0)
                }
            }
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .background(vm.order.status.color)
        }
        .padding(4)
        .onTapGesture {
//            print("KDSOrderView \(titleText) tapped")
            vm.incrementOrderStatus()
        }
//        .onAppear {
//            print("KDSOrderView.onAppear --> status.color: \(vm.order.status.color)")
//        }
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
