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
            HStack(alignment: .bottom, spacing: 0) {
                Text("Total")
                Spacer()
                Text(viewModel.orderTotalDisplay)
            }
            .font(DittoTypography.body)
            .padding(.vertical, 4)

            HStack(spacing: DittoLayout.gap) {
                Button("Clear", action: viewModel.clearCurrentOrderCart)
                    .buttonStyle(DittoButtonStyle(.secondary))
                    .disabled(viewModel.actionsDisabled)
                Button(action: viewModel.payCurrentOrder) {
                    Text(viewModel.payButtonLabel).frame(maxWidth: .infinity)
                }
                .buttonStyle(DittoButtonStyle())
                .disabled(viewModel.actionsDisabled)
            }
        }
    }
}
