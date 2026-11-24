///
//  POSView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

struct POSView: View {
    @StateObject private var viewModel: POSViewModel
    let isActive: Bool

    init(
        ordersRepository: OrdersRepository,
        saleItemsRepository: SaleItemsRepository,
        locationsRepository: LocationsRepository,
        isActive: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: POSViewModel(
            ordersRepository: ordersRepository,
            saleItemsRepository: saleItemsRepository,
            locationPublisher: locationsRepository.$currentLocationId.eraseToAnyPublisher(),
            locationId: { locationsRepository.currentLocationId }
        ))
        self.isActive = isActive
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                POSSplitLayout {
                    POSGridView()
                } order: {
                    POSOrderView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(viewModel)
        .onAppear { viewModel.setVisible(isActive) }
        .onChange(of: isActive) { viewModel.setVisible($0) }
        .onDisappear { viewModel.setVisible(false) }
    }
}
