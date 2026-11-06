//
//  KDSOrdersGridView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct KDSOrdersGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: KDSViewModel
    let ordersRepository: OrdersRepository
    let isActive: Bool
    @State var columns = [GridItem(.adaptive(minimum: 172), alignment: .top)]

    init(ordersRepository: OrdersRepository, isActive: Bool = true) {
        self.ordersRepository = ordersRepository
        self.isActive = isActive
        _viewModel = StateObject(wrappedValue: KDSViewModel(ordersRepository: ordersRepository))
    }

    var body: some View {
        Group {
            if viewModel.orders.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.orders, id: \.documentId.id) { order in
                            KDSOrderView(order, ordersRepository: ordersRepository)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(.background)
        .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
        .onAppear { viewModel.setVisible(isActive) }
        .onChange(of: isActive) { viewModel.setVisible($0) }
        .onDisappear { viewModel.setVisible(false) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No active orders")
                .font(.title3.weight(.semibold))
            Text("Orders entered in POS will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
