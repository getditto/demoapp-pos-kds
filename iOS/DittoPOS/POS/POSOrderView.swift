//
//  POSOrderView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoUI
import SwiftUI

struct POSOrderView: View {
    @EnvironmentObject var viewModel: POSViewModel

    var body: some View {
        VStack(spacing: 0) {
            orderContent.padding(8)
            POSOrderTotalView()
        }
    }

    private var orderContent: some View {
        VStack(spacing: 0) {
            Text(viewModel.orderTitle)
                .font(DittoTypography.body)
                .padding(.bottom, 8)
            divider()
                .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Section {
                        ForEach(viewModel.orderItems, id: \.id) { entry in
                            if let orderID = viewModel.currentOrder?.documentId {
                                POSOrderItemView(lineItemId: entry.id, item: entry.item, orderID: orderID, store: viewModel.photoStore)
                            }
                            divider()
                        }
                        .onChange(of: viewModel.orderItems.count) { _ in
                            if let last = viewModel.orderItems.last?.id {
                                withAnimation { proxy.scrollTo(last, anchor: .top) }
                            }
                        }
                        .onRotate { _ in
                            withAnimation { scrollToBottom(proxy: proxy) }
                        }
                    }
                }
            }
            .padding(.bottom, 4)
            .listStyle(.plain)
        }
    }

    func scrollToBottom(proxy: ScrollViewProxy) {
        guard let config = viewModel.scrollToBottomConfig() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + config.delay) {
            withAnimation { proxy.scrollTo(config.id, anchor: .bottom) }
        }
    }
}
