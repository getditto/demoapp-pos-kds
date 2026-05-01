//
//  CartLineItem.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Snapshot of a SaleItem at add-time — the receipt records the price the
// customer paid, not the current SaleItem price.
struct CartLineItem: Codable, Hashable, Equatable {
    let saleItemId: String
    let name: String
    let imageName: String
    let price: Price
    var qty: Int
    let createdAt: Date

    init(
        saleItemId: String,
        name: String,
        imageName: String,
        price: Price,
        qty: Int = 1,
        createdAt: Date = Date()
    ) {
        self.saleItemId = saleItemId
        self.name = name
        self.imageName = imageName
        self.price = price
        self.qty = qty
        self.createdAt = createdAt
    }

    init(from saleItem: SaleItem, qty: Int = 1) {
        self.init(
            saleItemId: saleItem.id,
            name: saleItem.name,
            imageName: saleItem.imageName,
            price: saleItem.price,
            qty: qty
        )
    }

    static func newLineItemId() -> String { UUID().uuidString }
}
