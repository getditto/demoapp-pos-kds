///
//  OrderView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct OrderView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    
    var body: some View {
//        NavigationView {
            VStack(spacing: 0) {
                // title view
                Text(barTitle)
                    .padding(.bottom, 8)
                divider()
                    .padding(.bottom, 8)
                
                // Order items scrollview
                ScrollView(showsIndicators: false) {
                    Section {
                        ForEach(dataVM.orderItems, id: \.self) { item in
                            OrderItemView(item)

                            divider()
                                .onTapGesture {
//                                    print("\(item) tapped")
                                    dataVM.addOrderItem(item)
                                }
                        }
                    }
                }
//                .border(.blue)
                .listStyle(.plain)
                
                // order total and pay buttons
                OrderTotalView()
                    .padding(.bottom, 16)
            }
    }
    
    var barTitle: String {
        "Order #\(dataVM.currentOrder?.id ?? "...")"
    }
    
}

struct OrderView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView()
    }
}
