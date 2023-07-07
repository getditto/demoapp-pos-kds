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

struct Location: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
//    var details: String?
    var menuItemIds = [String: Double]() // [menuItemID: price.amount]
}

extension Location {
    init(doc: DittoDocument) {
        self.id = doc["_id"].stringValue
        self.name = doc["name"].stringValue
//        self.details = doc["details"].string
        self.menuItemIds = doc["menuItemIds"].dictionaryValue as! [String: Double]
    }
}

extension Location {
    func docDictionary() -> [String: Any?] {
        [
            "_id": id,
            "name": name,
            "menuItemIds": menuItemIds
        ]
    }
}

extension Location {
    static var demoLocations: [Location] {
        [
            Location(id: "00001", name: "Ham\'s Burgers", menuItemIds: [String : Double]()),
            Location(id: "00002", name: "Sally\'s Salad Bar", menuItemIds: [String : Double]()),
            Location(id: "00003", name: "Kyle\'s Kabobs", menuItemIds: [String : Double]()),
            Location(id: "00004", name: "Franks\'s Falafels", menuItemIds: [String : Double]()),
            Location(id: "00005", name: "Cathy\'s Crepes", menuItemIds: [String : Double]()),
            Location(id: "00006", name: "Gilbert\'s Gumbo", menuItemIds: [String : Double]()),
            Location(id: "00007", name: "Tarra\'s Tacos", menuItemIds: [String : Double]())
        ]

    }
    
}
