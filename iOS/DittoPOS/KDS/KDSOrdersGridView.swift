///
//  KDSOrdersGridView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct KDSOrdersGridView: View {
    @Environment(\.horizontalSizeClass) private var HsizeClass
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm = KDS_VM()
    @State var columns = [GridItem(.adaptive(minimum: 172), alignment: .top)]

    var body: some View {
        ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns) {//, spacing: 24) {
                    ForEach(vm.orders) { order in                        
                        KDSOrderView(order)
                    }
                }

            .padding(.vertical, 8)
        }
        .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
    }
}

struct KDSOrdersGridView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrdersGridView()
    }
}
