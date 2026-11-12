//
//  POSOrderItemView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoUI
import SwiftUI

struct POSOrderItemView: View, Identifiable {
    let lineItemId: String
    let item: CartLineItem
    nonisolated var id: String { lineItemId }

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
        .font(DittoTypography.body)
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
