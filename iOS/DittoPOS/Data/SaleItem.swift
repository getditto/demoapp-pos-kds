//
//  SaleItem.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

struct SaleItem: Codable, Hashable {
    let documentId: DocumentID
    let name: String
    let imageName: String  // canonical wire key; resolve via ImageNameMapping
    let price: Price

    private enum CodingKeys: String, CodingKey {
        case documentId = "_id"
        case name, imageName, price
    }

    static let collectionName = "sale_items"
}

extension SaleItem: CustomStringConvertible {
    var description: String { "\(name): \(price.description)" }
}

extension SaleItem {
    static func seed(id: String, locationId: String, name: String, imageName: String, cents: Int) -> SaleItem {
        SaleItem(
            documentId: DocumentID(id: id, locationId: locationId),
            name: name,
            imageName: imageName,
            price: Price(cents: cents)
        )
    }
}
