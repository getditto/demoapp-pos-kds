///
//  OrderItem.swift
//  DittoPOS
//
//  Created by Eric Turner on 7/3/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

/// A model object for UI/non-ditto usage with a unique ID, representing a menuItem
///  and the number of these menuItems included in a given order
struct OrderItem: Identifiable {
    let id: String
    let menuItem: MenuItem
    var price: Price { menuItem.price }
    var title: String { menuItem.title }
    let createdOnStr: String
    let createdOn: Date
}

extension OrderItem {
    // for initializing from Order.orderItems keys
    init(id: String, menuItem: MenuItem) { // initialized with string format as "uuid_timestamp"
        let parts = id.split(separator: "_")
        
        assert(parts.count == 2, "OrderItem id string initialization error")
        
        self.id = String(parts[0])
        self.createdOnStr = String(parts[1])
        self.createdOn = DateFormatter.isoDate.date(from: createdOnStr)!
        self.menuItem = menuItem
    }
    
    // for initializing new orderItem object from selected menuItem
    init(menuItem: MenuItem) {
        self.createdOn = Date()
        self.createdOnStr = DateFormatter.isoDate.string(from: createdOn)
        self.id = "\(UUID().uuidString)_\(createdOnStr)"
        self.menuItem = menuItem
    }
}
