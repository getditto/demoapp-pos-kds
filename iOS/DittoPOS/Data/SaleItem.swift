//
//  SaleItem.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

struct SaleItem: Decodable, Hashable, Sendable {
    let documentId: DocumentID
    let name: String
    let imageName: String
    let price: Price
    let quantity: Int64?
    let image: PhotoReference?

    private enum CodingKeys: String, CodingKey {
        case documentId = "_id"
        case name, imageName, price, quantity, image
    }

    init(documentId: DocumentID, name: String, imageName: String, price: Price, quantity: Int64? = nil, image: PhotoReference? = nil) {
        self.documentId = documentId
        self.name = name
        self.imageName = imageName
        self.price = price
        self.quantity = quantity
        self.image = image
    }

    var metadata: SaleItemMetadata {
        SaleItemMetadata(documentId: documentId, name: name, imageName: imageName, price: price)
    }

    static let collectionName = "sale_items"
}

struct SaleItemMetadata: Codable, Hashable, Sendable {
    let documentId: DocumentID
    let name: String
    let imageName: String
    let price: Price

    private enum CodingKeys: String, CodingKey {
        case documentId = "_id"
        case name, imageName, price
    }
}

struct SaleItemCreation: Encodable, Sendable {
    let metadata: SaleItemMetadata
    let initialQuantity: Int64

    private enum CodingKeys: String, CodingKey {
        case quantity
    }

    func encode(to encoder: Encoder) throws {
        try metadata.encode(to: encoder)
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(initialQuantity, forKey: .quantity)
    }
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
