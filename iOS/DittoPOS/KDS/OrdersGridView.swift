///
//  OrdersGridView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

//class OrdersVM: ObservableObject {
//    @Published var orders = [Order]()
//    
//    
//    init() {
//        
//    }
//}

struct OrdersGridView: View {
    @Environment(\.horizontalSizeClass) private var HsizeClass
    @StateObject var vm = KDS_VM()
    @State var columns = [GridItem]()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(vm.orders) { order in
                        KDSOrderView(order)
//                            .frame(width: 100, height: 100)
                            .onTapGesture {
                                print("order tapped")
                            }
//                            .border(.purple)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear { print("OrdersGridView.onAppear"); columns = cols() }
    }
    
    func cols() -> [GridItem] {
        [GridItem(.adaptive(minimum: itemSide))]
    }
    
    var itemSide: CGFloat {
//        HsizeClass == .compact ? 80 : 160
        HsizeClass == .compact ? 80 : 160
    }
}

struct OrdersGridView_Previews: PreviewProvider {
    static var previews: some View {
        OrdersGridView()
    }
}
