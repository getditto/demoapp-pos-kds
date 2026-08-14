//
//  POSOrderTotalView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct POSOrderTotalView: View {
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                Text("Total")
                Spacer()
                Text(viewModel.orderTotalDisplay)
            }
            .scaledFont(size: 16)
            .padding(.vertical, 4)

            HStack {
                Button {
                    viewModel.clearCurrentOrderCart()
                } label: {
                    Text("X").font(.largeTitle)
                }
                .clipShape(Circle())
                .tint(.red)
                .disabled(viewModel.actionsDisabled)

                Spacer()

                Button {
                    viewModel.payCurrentOrder()
                } label: {
                    Text(viewModel.payButtonLabel)
                        .frame(maxWidth: .infinity, maxHeight: 36.0)
                }
                .tint(.green)
                .disabled(viewModel.actionsDisabled)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
        }
    }
}
