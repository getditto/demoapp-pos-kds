///
//  KDSView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct KDSView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    
    var body: some View {
        OrdersStatusView()
    }
}

struct KDSView_Previews: PreviewProvider {
    static var previews: some View {
        KDSView()
    }
}
