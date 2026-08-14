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
    @EnvironmentObject var layoutViewModel: POSLayoutViewModel

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: layoutViewModel.gridColumns(for: horizontalSizeClass)) {
                    ForEach(viewModel.saleItems, id: \.self) { item in
                        let side = layoutViewModel.itemSide(for: horizontalSizeClass)
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
}
