///
//  POSOrderItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

extension POSOrderItemView: Identifiable {
    var id: String { item.id }
}

struct POSOrderItemView: View {
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
        .scaledFont(size: 16)
    }
}

struct POSOrderItemView_Previews: PreviewProvider {
    static var previews: some View {
        POSOrderItemView(
            OrderItem(saleItem: SaleItem.demoItems[0])
        )
    }
}
