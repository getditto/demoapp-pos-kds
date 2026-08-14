//
//  SaleItemView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct SaleItemView: View {
    let item: SaleItem

    init(_ item: SaleItem, length: CGFloat = 0) {
        self.item = item
    }

    var body: some View {
        VStack {
            Spacer()
            Image(ImageNameMapping.assetName(for: item.imageName))
                .resizable()

            Text(item.name)
                .scaledFont(size: 16)
        }
        .lineLimit(1)
        .padding(0)
    }
}

struct POSItemView_Previews: PreviewProvider {
    static var previews: some View {
        SaleItemView(
            SaleItem.seed(
                id: "preview",
                locationId: "preview",
                name: "Burger",
                imageName: "burger",
                cents: 850
            ),
            length: 80
        )
    }
}
