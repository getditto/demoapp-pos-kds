//
//  POSOrderTotalView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import AppUI
import SwiftUI

struct POSOrderTotalView: View {
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: AppLayout.gap) {
                    Text("Total")
                    Spacer()
                    Text(viewModel.orderTotalDisplay)
                }
                VStack(alignment: .leading, spacing: AppLayout.gap) {
                    Text("Total")
                    Text(viewModel.orderTotalDisplay).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .font(AppTypography.body)
            .frame(minHeight: 40)

            payButton
            clearButton
        }
        .padding(AppLayout.padding)
    }

    private var clearButton: some View {
        Button(action: viewModel.clearCurrentOrderCart) {
            Text("Clear cart").frame(maxWidth: .infinity)
        }
        .buttonStyle(AppButtonStyle(.text))
        .disabled(viewModel.actionsDisabled)
    }

    private var payButton: some View {
        Button(action: viewModel.payCurrentOrder) {
            Text("\(viewModel.payButtonLabel) \(viewModel.orderTotalDisplay)").frame(maxWidth: .infinity)
        }
        .buttonStyle(AppButtonStyle())
        .disabled(viewModel.actionsDisabled)
    }
}
