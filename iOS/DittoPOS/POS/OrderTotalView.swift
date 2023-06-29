///
//  OrderTotalView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/23/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct OrderTotalView: View {
    @ObservedObject var dataVM = DataViewModel.shared
    
    var body: some View {
        VStack {
            HStack {
                Text("Total")
                Spacer()
                Text(dataVM.currentOrderTotal().toCurrency())
            }
            divider()
                .padding(.bottom, 8)
            
            HStack {
                Button {
                    print("Cancel button tapped")
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
                .tint(.red)

                Spacer()
                
                Button {
                    print("Pay button tapped")
                } label: {
                    Text("Pay")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
                .tint(.green)
            }
        }
    }
}

struct OrderTotalView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTotalView()
            .frame(width: .screenWidth * 0.8)
    }
}
