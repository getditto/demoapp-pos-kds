///
//  Location.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation

extension Location: Codable {}

/*
 NOTE:
 Each Location should have its own collection of SaleItems, which is not (yet?) implemented.
 This demo app uses the SaletItem.demoItems collection for all locations.
 */

struct Location: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
//    var details: String?
    var saleItemIds = [String: Double]() // [saleItemID: price.amount]
}

extension Location {
    init(doc: DittoDocument) {
        self.id = doc["_id"].stringValue
        self.name = doc["name"].stringValue
//        self.details = doc["details"].string
        self.saleItemIds = doc["saleItemIds"].dictionaryValue as! [String: Double]
    }
}

extension Location {
    func docDictionary() -> [String: Any?] {
        [
            "_id": id,
            "name": name,
            "saleItemIds": saleItemIds
        ]
    }
}

extension Location {
    static var demoLocations: [Location] {
        [
            Location(id: "00001", name: "Ham\'s Burgers", saleItemIds: [String : Double]()),
            Location(id: "00002", name: "Sally\'s Salad Bar", saleItemIds: [String : Double]()),
            Location(id: "00003", name: "Kyle\'s Kabobs", saleItemIds: [String : Double]()),
            Location(id: "00004", name: "Franks\'s Falafels", saleItemIds: [String : Double]()),
            Location(id: "00005", name: "Cathy\'s Crepes", saleItemIds: [String : Double]()),
            Location(id: "00006", name: "Gilbert\'s Gumbo", saleItemIds: [String : Double]()),
            Location(id: "00007", name: "Tarra\'s Tacos", saleItemIds: [String : Double]())
        ]

    }
    
}
