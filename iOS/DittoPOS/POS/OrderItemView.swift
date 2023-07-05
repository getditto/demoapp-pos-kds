///
//  OrderItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

extension OrderItemView: Identifiable {
    var id: String { item.createdOnStr }
}

struct OrderItemView: View {
    let item: OrderItem

    init(_ item: OrderItem) {
        self.item = item        
    }
    
    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            Text(item.price.description)
        }
        .padding(.horizontal, 16)
    }
}

struct OrderItemView_Previews: PreviewProvider {
    static var previews: some View {
        OrderItemView(
            OrderItem(menuItem: MenuItem.demoItems[0])
        )
    }
}
