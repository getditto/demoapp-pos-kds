//
//  CartLineItem.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Catalog edits must not rewrite the item details or prices recorded on an order.
struct CartLineItem: Codable, Hashable, Equatable, Sendable {
    let saleItemId: String
    let name: String
    let imageName: String?
    let price: Price
    var qty: Int
    let createdAt: Date
    let image: PhotoReference?

    private enum CodingKeys: String, CodingKey {
        case saleItemId, name, imageName, price, qty, createdAt, image
    }

    init(
        saleItemId: String,
        name: String,
        imageName: String? = nil,
        price: Price,
        qty: Int = 1,
        createdAt: Date = Date(),
        image: PhotoReference? = nil
    ) {
        self.saleItemId = saleItemId
        self.name = name
        self.imageName = imageName
        self.price = price
        self.qty = qty
        self.createdAt = createdAt
        self.image = image
    }

    init(from saleItem: SaleItem, qty: Int = 1) {
        self.init(
            saleItemId: saleItem.documentId.id,
            name: saleItem.name,
            imageName: saleItem.imageName,
            price: saleItem.price,
            qty: qty,
            image: saleItem.image
        )
    }

    // Photo references use the explicitly typed binding in OrderCommands.
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(saleItemId, forKey: .saleItemId)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(imageName, forKey: .imageName)
        try values.encode(price, forKey: .price)
        try values.encode(qty, forKey: .qty)
        try values.encode(createdAt, forKey: .createdAt)
    }

    static func newLineItemId() -> String { UUID().uuidString }
}
