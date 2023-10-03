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
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(dataVM.saleItems, id: \.self) { item in
                        SaleItemView(item, length: itemSide)
                            .frame(width: itemSide, height: itemSide + 8)
                            .onTapGesture {
//                                print("\(item) tapped")
                                dataVM.addOrderItem(item)
                            }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear { columns = cols() }
//        .onAppear { print("POSGridView.onAppear")
//        .onRotate { orient in
//            guard orient.isLandscape || orient.isPortrait else { return }
//            print("MenuGrid.onRotate: orientation: \(orient.description)")
//            DispatchQueue.main.async {
//                columns = cols()
//            }
//        }
    }
    
    func cols() -> [GridItem] {
        [GridItem(.adaptive(minimum: itemSide))]
    }
    
    var itemSide: CGFloat {
        HsizeClass == .compact ? 80 : 160
    }
}

struct POSGridView_Previews: PreviewProvider {
    static var previews: some View {
        POSGridView()
    }
}
