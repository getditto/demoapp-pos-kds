///
//  POSOrderItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct POSOrderItemView: View, Identifiable {
    let lineItemId: String
    let item: CartLineItem
    var id: String { lineItemId }

    init(lineItemId: String, _ item: CartLineItem) {
        self.lineItemId = lineItemId
        self.item = item
    }

    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text(item.price.description)
        }
        .scaledFont(size: 16)
    }
}

struct POSOrderItemView_Previews: PreviewProvider {
    static var previews: some View {
        POSOrderItemView(
            lineItemId: "preview",
            CartLineItem(
                saleItemId: "00001",
                name: "Burger",
                imageName: "burger",
                price: Price(cents: 850)
            )
        )
    }
}
