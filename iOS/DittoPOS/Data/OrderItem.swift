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
struct OrderItem {
    let menuItem: MenuItem
    var createdOn: Date = Date()
    
    var price: Price { menuItem.price }
    var title: String { menuItem.title }    
    var createdOnStr: String { DateFormatter.isoDate.string(from: createdOn) }
}

extension OrderItem: Identifiable {
    var id: String { createdOnStr }
}
