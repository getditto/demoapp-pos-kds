///
//  KDSOrderItemView.swift
//  DittoPOS
//
//  Created by Eric Turner on 8/31/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct KDSOrderItemView: View {
    let title: String
    let count: Int
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(count))
        }
        .padding(4)
    }
}


struct KDSOrderItemView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrderItemView(title: SaleItem.demoItems[0].title, count: 3)
    }
}
