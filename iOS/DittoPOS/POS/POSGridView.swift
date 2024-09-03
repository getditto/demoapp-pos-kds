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
                #if os(tvOS)
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 10) {
                    ForEach(dataVM.saleItems, id: \.self) { item in
                        Button(action: {
                            dataVM.addOrderItem(item)
                        }, label: {
                            VStack{
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                Text(item.title)
                                    .font(.body)
                            }
                        })
                    }
                }
                #else
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
                #endif
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
