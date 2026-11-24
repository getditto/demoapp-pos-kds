//
//  POSGridView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import AppUI
import SwiftUI

struct POSGridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        let layout = POSGridViewModel(sizeClass: horizontalSizeClass)
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: layout.columns) {
                ForEach(viewModel.saleItems, id: \.documentId) { item in
                    SaleItemView(item: item, store: viewModel.photoStore)
                        .frame(width: layout.itemSide, height: layout.itemHeight)
                        .onTapGesture {
                            viewModel.addOrderItem(item)
                        }
                }
            }
            .padding(.vertical, AppLayout.padding)
        }
    }
}
