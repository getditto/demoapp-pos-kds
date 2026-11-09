//
//  POSGridView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct POSGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: POSGridMetrics.gridColumns(for: horizontalSizeClass)) {
                ForEach(viewModel.saleItems, id: \.self) { item in
                    let side = POSGridMetrics.itemSide(for: horizontalSizeClass)
                    SaleItemView(item, length: side)
                        .frame(width: side, height: side + 8)
                        .onTapGesture {
                            viewModel.addOrderItem(item)
                        }
                }
            }
            .padding(.vertical, 16)
        }
    }
}
