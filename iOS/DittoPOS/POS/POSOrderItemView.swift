//
//  POSOrderItemView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import DittoUI
import SwiftUI

struct POSOrderItemView: View, Identifiable {
    let lineItemId: String
    let item: CartLineItem
    let orderID: DocumentID
    let store: DittoStore
    nonisolated var id: String { lineItemId }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                photo
                Text(item.name).fixedSize()
                Spacer()
                Text(item.price.description).fixedSize()
            }
            HStack {
                photo
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                    Text(item.price.description).fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(DittoTypography.body)
    }

    private var photo: some View {
        OrderLinePhotoView(line: item, orderID: orderID, store: store)
            .frame(width: 40, height: 40)
    }
}
