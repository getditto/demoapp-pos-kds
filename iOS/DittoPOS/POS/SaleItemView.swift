///
//  POSItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct SaleItemView: View {
    let item: SaleItem
    
    init(_ item: SaleItem, length: CGFloat = 0) {
        self.item = item
    }
    
    var body: some View {
        VStack {
            Spacer()
            Image(item.imageName)
                .resizable()
                
            Text(item.title)
                .scaledFont(size: 16)
        }
        .lineLimit(1)
        .padding(0)
    }
}

struct POSItemView_Previews: PreviewProvider {
    static var previews: some View {
        SaleItemView(SaleItem.demoItems.first!, length: 80)
    }
}
