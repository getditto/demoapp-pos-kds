//
//  KDSOrderItemView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

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
        KDSOrderItemView(title: "Burger", count: 3)
    }
}
