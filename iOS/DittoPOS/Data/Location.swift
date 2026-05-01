///
//  Location.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/14/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

struct Location: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }

    static let collectionName = "locations"
}

// MARK: - Query
extension Location {
    var insertDefaultQuery: DittoQuery {
        (
            string: """
                INSERT INTO \(Self.collectionName)
                INITIAL DOCUMENTS (deserialize_json(:json))
                """,
            args: ["json": dittoJSONString()]
        )
    }

    var insertNewQuery: DittoQuery {
        (
            string: """
                INSERT INTO \(Self.collectionName)
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            args: ["json": dittoJSONString()]
        )
    }

    static var selectAllQuery: DittoQuery {
        (
            string: "SELECT * FROM \(Self.collectionName)",
            args: [:]
        )
    }
}
