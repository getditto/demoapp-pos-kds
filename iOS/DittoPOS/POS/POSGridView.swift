///
//  POSGridView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct POSGridView: View {
    @Environment(\.horizontalSizeClass) private var HsizeClass    
    @ObservedObject var dataVM = POS_VM.shared
    @State var columns = [GridItem]()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns) {
                    ForEach(dataVM.saleItems, id: \.self) { item in
                        SaleItemView(item, length: itemSide)
                            .frame(width: itemSide, height: itemSide + 8)
                            .onTapGesture {
                                dataVM.addOrderItem(item)
                            }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear { columns = cols() }
    }
    
    func cols() -> [GridItem] {
        [GridItem(.adaptive(minimum: HsizeClass == .compact ? 100 : 160), alignment: .top)]
    }
    
    var itemSide: CGFloat {
        HsizeClass == .compact ? 100 : 160
    }
}

struct POSGridView_Previews: PreviewProvider {
    static var previews: some View {
        POSGridView()
    }
}
