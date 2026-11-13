//
//  SaleItemView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import DittoUI
import SwiftUI

struct SaleItemView: View {
    let item: SaleItem
    let store: DittoStore

    var body: some View {
        VStack {
            Spacer()
            ProductPhotoView(reference: item.image, owner: item.documentId, store: store)

            Text(item.name)
                .font(DittoTypography.body)
        }
        .lineLimit(1)
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
