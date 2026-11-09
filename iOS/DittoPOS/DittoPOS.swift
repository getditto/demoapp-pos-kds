///
//  DittoPOSApp.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

@main
struct DittoPOS: App {
    @StateObject private var appearance = AppearanceSettings(defaults: Settings.defaults)
    @StateObject private var locationsRepository: LocationsRepository
    @StateObject private var ordersRepository: OrdersRepository
    @StateObject private var saleItemsRepository: SaleItemsRepository

    init() {
        let manager = DittoManager.shared
        let locationsRepository = LocationsRepository(ditto: manager.ditto, updateSyncGroup: { locationId in
            if let locationId { manager.applySyncGroup(locationId: locationId) }
            else { manager.resetSyncGroup() }
        })
        let ordersRepository = OrdersRepository(
            ditto: manager.ditto,
            locationPublisher: locationsRepository.$currentLocationId.eraseToAnyPublisher()
        )
        let saleItemsRepository = SaleItemsRepository(
            ditto: manager.ditto,
            locationPublisher: locationsRepository.$currentLocationId.eraseToAnyPublisher()
        )
        _locationsRepository = StateObject(wrappedValue: locationsRepository)
        _ordersRepository = StateObject(wrappedValue: ordersRepository)
        _saleItemsRepository = StateObject(wrappedValue: saleItemsRepository)
    }

    var body: some Scene {
        WindowGroup {
            AppTheme(appearance: appearance) {
                MainView(locationsRepository: locationsRepository)
                    .environmentObject(appearance)
            }
                .environmentObject(locationsRepository)
                .environmentObject(ordersRepository)
                .environmentObject(saleItemsRepository)
                .task {
                    await DemoSeeder(store: DittoManager.shared.ditto.store).seedAll()
                    try! await ordersRepository.runEvictionIfDue()
                }
        }
    }
}
