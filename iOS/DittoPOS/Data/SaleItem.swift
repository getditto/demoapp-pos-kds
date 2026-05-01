///
//  SaleItem.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

struct SaleItem: Identifiable, Codable, Hashable {
    let _id: DocumentID
    let name: String
    let imageName: String  // canonical wire key; resolve via ImageNameMapping
    let price: Price

    var id: String { _id.id }
    var locationId: String { _id.locationId }

    static let collectionName = "sale_items"
}

extension SaleItem: CustomStringConvertible {
    var description: String { "\(name): \(price.description)" }
}

extension SaleItem {
    static func seed(id: String, locationId: String, name: String, imageName: String, cents: Int) -> SaleItem {
        SaleItem(
            _id: DocumentID(id: id, locationId: locationId),
            name: name,
            imageName: imageName,
            price: Price(cents: cents)
        )
    }
}
