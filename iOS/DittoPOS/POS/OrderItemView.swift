///
//  OrderItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct OrderItemView: View {
    let menuItem: MenuItem
    
    init(_ item: MenuItem) {
        self.menuItem = item
    }
    
    var body: some View {
        HStack {
            Text(menuItem.title)
            Spacer()
            Text(menuItem.price.description)
        }
        .padding(.horizontal, 16)
    }
}

struct OrderItemView_Previews: PreviewProvider {
    static var previews: some View {
        OrderItemView(MenuItem.demoItems[0])
    }
}
