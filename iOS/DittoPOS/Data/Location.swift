///
//  Location.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation

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

    var _id: String { id } // For DittoDecodable

    static let collectionName = "locations"
}

// MARK: - Initializer
extension Location: DittoDecodable {
    init(value: [String: Any?]) {
        self = Location(
            id: value["_id"] as! String,
            name: value["name"] as! String,
            saleItemIds: value["saleItemIds"] as? [String: Double] ?? [:]
        )
    }
}

// MARK: - Query
extension Location {
    var insertDefaultQuery: DittoQuery {
        (
            string: """
                INSERT INTO COLLECTION \(Self.collectionName) (saleItemIds MAP)
                INITIAL DOCUMENTS (:new)
                """,
            args: [
                "new": [
                    "_id": id,
                    "name": name,
                    "saleItemIds": saleItemIds
                ]
            ]
        )
    }

    var insertNewQuery: DittoQuery {
        (
            string: """
                INSERT INTO COLLECTION \(Self.collectionName) (saleItemIds MAP)
                DOCUMENTS (:new)
                ON ID CONFLICT DO UPDATE
            """,
            args: [
                "new": [
                    "_id": id,
                    "name": name,
                    "saleItemIds": saleItemIds
                ]
            ]
        )
    }

    static var selectAllQuery: DittoQuery {
        (
            string: """
                SELECT * FROM COLLECTION \(Self.collectionName) (saleItemIds MAP)
            """,
            args: [:]
        )
    }
    
    // Used in initial registration before currentLocationId is set. In this demo, this value
    // does not match any locations, so queries for this locationId return no results.
    static var defaultLocation: String {
        "00000"
    }
}

// MARK: - Demo dummy data
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

    // use case: filtering DittoService.allLocationDocs to only demo locations
    static var demoLocationsIds: [String] {
        demoLocations.map { $0.id }
    }
}
