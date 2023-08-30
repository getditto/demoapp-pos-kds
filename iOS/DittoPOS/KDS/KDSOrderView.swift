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
    private var cancelleables = Set<AnyCancellable>()
        
    init(_ order: Order) {
        self.order = order
        
        DittoService.shared.orderPublisher(order)
            .filter( {$0.status == .inProcess || $0.status == .processed} )
            .sink {[weak self] updatedOrder in
                self?.order = updatedOrder
            }
            .store(in: &cancelleables)
    }
}

struct KDSOrderView: View {
    @StateObject var vm: KDSOrderVM
    
    init(_ order: Order) {
        self._vm = StateObject(wrappedValue: KDSOrderVM(order))
        
        print("KDSOrderView.init() --> order.items: \(order.orderItems.count)")
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // title view
                Text(titleBarText)
                    .padding(.bottom, 8)
                divider()
                    .padding(.bottom, 8)
                
                Text("\(vm.order.orderItems.count) items")
                divider()
                
                // Order items
                ForEach(vm.order.orderItems) { item in
                    OrderItemView(item)

                    divider()
                }
//                .border(.blue)
            }
//            .border(.purple)
    }
    
    var titleBarText: String {
        "\(DateFormatter.shortTime.string(from: vm.order.createdOn)) | \(vm.order.title)"
    }
}

struct KDSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrderView(Order.preview())
    }
}
