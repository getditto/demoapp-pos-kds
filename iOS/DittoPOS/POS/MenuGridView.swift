///
//  MenuGridView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct MenuGridView: View {
    @Environment(\.horizontalSizeClass) private var HsizeClass
    @ObservedObject var dataVM = DataViewModel.shared
    @State var columns = [GridItem]()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(dataVM.menuItems, id: \.self) { item in
                        MenuItemView(item, length: itemSide)
                            .onTapGesture {
                                print("\(item) tapped")
                                dataVM.addOrderItem(item)
                            }
                            .frame(width: itemSide, height: itemSide + 8)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear { print("MenuGrid.onAppear"); columns = cols() }
        .onRotate { newOrientation in
            DispatchQueue.main.async {
                columns = cols()
            }
        }
    }
    
    func cols() -> [GridItem] {
        [GridItem(.adaptive(minimum: itemSide))]
    }
    
    var itemSide: CGFloat {
        HsizeClass == .compact ? 80 : 160
    }
}

struct MenuGridView_Previews: PreviewProvider {
    static var previews: some View {
        MenuGridView()
    }
}
