///
//  DittoPOSApp.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

@main
struct DittoPOS: App {
    var body: some Scene {
        WindowGroup {
            // Hosted unit tests create their own isolated stores. Do not start
            // the demo's singleton, seeders or sync in the test host.
            if ProcessInfo.processInfo.environment["DITTO_UNIT_TESTS"] == "1" {
                EmptyView()
            } else {
                DemoRootView()
            }
        }
    }
}

private struct DemoRootView: View {
    @StateObject private var locationsRepository: LocationsRepository
    @StateObject private var ordersRepository: OrdersRepository
    @StateObject private var saleItemsRepository: SaleItemsRepository

    init() {
        let manager = DittoManager.shared
        let locationsRepository = LocationsRepository(dittoManager: manager)
        let ordersRepository = OrdersRepository(
            dittoManager: manager,
            locationsRepository: locationsRepository
        )
        let saleItemsRepository = SaleItemsRepository(
            dittoManager: manager,
            locationsRepository: locationsRepository
        )
        _locationsRepository = StateObject(wrappedValue: locationsRepository)
        _ordersRepository = StateObject(wrappedValue: ordersRepository)
        _saleItemsRepository = StateObject(wrappedValue: saleItemsRepository)
    }

    var body: some View {
        MainView(locationsRepository: locationsRepository)
            .environmentObject(locationsRepository)
            .environmentObject(ordersRepository)
            .environmentObject(saleItemsRepository)
            .task {
                await DemoSeeder(store: DittoManager.shared.ditto.store).seedAll()
                await ordersRepository.runEvictionIfDue()
            }
    }
}
