///
//  KDSOrdersGridView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct KDSOrdersGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var vm = KDS_VM()
    #if os(tvOS)
    @State var columns = [GridItem(.adaptive(minimum: 300), alignment: .top)]
    #else
    @State var columns = [GridItem(.adaptive(minimum: 172), alignment: .top)]
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns) {
                ForEach(vm.orders) { order in
                    KDSOrderView(order)
                }
            }
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
    }
}

struct KDSOrdersGridView_Previews: PreviewProvider {
    static var previews: some View {
        KDSOrdersGridView(vm: Fixtures.kdsVM)
    }
}
