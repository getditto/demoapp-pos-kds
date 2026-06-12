//
//  MainView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

enum TabViews: Int, Identifiable {
    case pos=1, kds, locations
    var id: Self { self }
}

struct MainView: View {
    @EnvironmentObject var ordersRepository: OrdersRepository
    @EnvironmentObject var saleItemsRepository: SaleItemsRepository
    @EnvironmentObject var locationsRepository: LocationsRepository

    @StateObject private var viewModel: MainViewModel

    init(locationsRepository: LocationsRepository) {
        _viewModel = StateObject(wrappedValue: MainViewModel(locationsRepository: locationsRepository))
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $viewModel.selectedTab) {
                POSView(
                    ordersRepository: ordersRepository,
                    saleItemsRepository: saleItemsRepository,
                    locationsRepository: locationsRepository
                )
                .tabItem {
                    Label("POS", systemImage: "dot.squareshape")
                }
                .tag(TabViews.pos)

                KDSView(ordersRepository: ordersRepository)
                    .tabItem {
                        Label("KDS", systemImage: "square.grid.3x1.below.line.grid.1x2")
                    }
                    .tag(TabViews.kds)

                LocationsView(locationsRepository: locationsRepository)
                    .tabItem {
                        Label("Locations", systemImage: "globe")
                    }
                    .tag(TabViews.locations)
            }
            .sheet(isPresented: $viewModel.presentSettingsView) {
                SettingsView()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        viewModel.presentSettingsView = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle(viewModel.mainTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear { viewModel.ensureLocationSelected() }
        }
    }
}
