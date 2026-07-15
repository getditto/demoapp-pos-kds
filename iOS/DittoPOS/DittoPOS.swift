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

    var body: some Scene {
        WindowGroup {
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
}
