///
//  POSOrderView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct POSOrderView: View {
    @ObservedObject var dataVM = POS_VM.shared
    
    var body: some View {
            VStack(spacing: 0) {
                // title view
                Text(barTitle)
                    .padding(.bottom, 8)
                divider()
                    .padding(.bottom, 8)
                
                // Order items scrollview
                ScrollView(showsIndicators: false) {
                    Section {
//                        ForEach(dataVM.currentOrderItems) { item in
                        if let orderItems = dataVM.currentOrder?.orderItems {
                            ForEach(orderItems) { item in
                                OrderItemView(item)                                
                                divider()
                            }
                        }
                    }
                }
//                .border(.blue)
                .listStyle(.plain)
                
                // order total and pay buttons
                OrderTotalView()
            }
//            .border(.purple)
    }
    
    var barTitle: String {
        "Order #\(dataVM.currentOrder?.title ?? "...")"
    }
}

struct POSOrderView_Previews: PreviewProvider {
    static var previews: some View {
        POSOrderView()
    }
}
