///
//  OrderTotalView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/23/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct OrderTotalView: View {
//    @Environment(\.horizontalSizeClass) private var HsizeClass
    @ObservedObject var dataVM = DataViewModel.shared
//    @State var cancelBtnTitle: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            divider()
            HStack(alignment: .bottom, spacing: 0) {
                Text("Total")
                Spacer()
                Text(dataVM.currentOrderTotal().toCurrency())
            }
//            divider()
                .padding(.bottom, 4)
            
            HStack {
                Button {
                    print("Cancel button tapped")
                } label: {
//                    Text(cancelBtnTitle)
                    Text("X").font(.largeTitle)
                }
                .clipShape(Circle())
                .tint(.red)

                Spacer()
                
                Button {
                    print("Pay button tapped")
                } label: {
                    Text("Pay")
                        .frame(maxWidth: .infinity, maxHeight: 36.0)
                }
                .tint(.green)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
        }
//        .onRotate { _ in
//            DispatchQueue.main.async {
//                cancelBtnTitle = updateCancelTitle()
//            }
//        }
    }
    
//    func updateCancelTitle() -> String {
//        HsizeClass == .compact && UIScreen.isPortrait ? "X" : "Cancel"
//    }
}

struct OrderTotalView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTotalView()
            .frame(width: .screenWidth * 0.8)
    }
}
