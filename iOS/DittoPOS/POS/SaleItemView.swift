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
                .scaledToFit()

            Text(item.name)
                .scaledFont(size: 16)
        }
        .lineLimit(1)
        .padding(0)
        // Fill the cell and make all of it tappable. The image is scaled to
        // fit, so it no longer covers the cell's full width, and taps only
        // land on drawn content by default.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
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
