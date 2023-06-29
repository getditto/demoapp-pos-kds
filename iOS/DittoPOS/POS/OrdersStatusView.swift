///
//  OrdersStatusView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct OrdersStatusView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    
    var body: some View {
        Text("KDS - Orders Status")
    }
}

struct OrdersStatusView_Previews: PreviewProvider {
    static var previews: some View {
        OrdersStatusView()
    }
}
