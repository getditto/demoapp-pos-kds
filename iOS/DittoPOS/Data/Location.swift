//
//  Location.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

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
