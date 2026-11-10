//
//  POSOrderTotalView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoUI
import SwiftUI

struct POSOrderTotalView: View {
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: DittoLayout.gap) {
                    Text("Total")
                    Spacer()
                    Text(viewModel.orderTotalDisplay)
                }
                VStack(alignment: .leading, spacing: DittoLayout.gap) {
                    Text("Total")
                    Text(viewModel.orderTotalDisplay).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .font(DittoTypography.body)
            .padding(.vertical, 4)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: DittoLayout.gap) {
                    clearButton
                    payButton
                }
                VStack(spacing: DittoLayout.gap) {
                    clearButton.frame(maxWidth: .infinity)
                    payButton
                }
            }
        }
    }

    private var clearButton: some View {
        Button("Clear", action: viewModel.clearCurrentOrderCart)
            .buttonStyle(DittoButtonStyle(.secondary))
            .disabled(viewModel.actionsDisabled)
    }

    private var payButton: some View {
        Button(action: viewModel.payCurrentOrder) {
            Text(viewModel.payButtonLabel).frame(maxWidth: .infinity)
        }
        .buttonStyle(DittoButtonStyle())
        .disabled(viewModel.actionsDisabled)
    }
}
