///
//  POSView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

@MainActor class POSLayoutViewModel: ObservableObject {
    @Published var menuViewWidth: CGFloat = 0.0
    @Published var orderViewWidth: CGFloat = 0.0
    init() {
        updateWidths()
    }

    func updateWidths() {
        menuViewWidth = .screenWidth * 0.56
        orderViewWidth = .screenWidth * 0.40
    }

    func itemSide(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 100 : 160
    }

    func gridColumns(for sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        [GridItem(.adaptive(minimum: itemSide(for: sizeClass)), alignment: .top)]
    }
}

struct POSView: View {
    @StateObject private var layoutViewModel = POSLayoutViewModel()
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
            locationPublisher: locationsRepository.$currentLocation.eraseToAnyPublisher(),
            locationId: { locationsRepository.currentLocationId }
        ))
        self.isActive = isActive
    }

    var body: some View {
        HStack {
            POSGridView()
                .frame(width: layoutViewModel.menuViewWidth)

            Divider()

            POSOrderView()
                .padding(8)
                .frame(width: layoutViewModel.orderViewWidth)
        }
        .environmentObject(viewModel)
        .environmentObject(layoutViewModel)
        .onAppear { viewModel.setVisible(isActive) }
        .onChange(of: isActive) { viewModel.setVisible($0) }
        .onDisappear { viewModel.setVisible(false) }
        .onRotate { orient in
            guard orient.isLandscape || orient.isPortrait else { return }
            DispatchQueue.main.async {
                layoutViewModel.updateWidths()
            }
        }
    }
}
