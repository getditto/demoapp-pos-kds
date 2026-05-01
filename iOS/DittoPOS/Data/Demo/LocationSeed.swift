//
//  LocationSeed.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// Demo-only data.

import Foundation

enum LocationSeed {
    static let demoLocations: [Location] = [
        Location(id: "00001", name: "Ham's Burgers"),
        Location(id: "00002", name: "Sally's Salad Bar"),
        Location(id: "00003", name: "Kyle's Kabobs"),
        Location(id: "00004", name: "Frank's Falafels"),
        Location(id: "00005", name: "Cathy's Crepes"),
        Location(id: "00006", name: "Gilbert's Gumbo"),
        Location(id: "00007", name: "Tarra's Tacos")
    ]

    static let demoLocationIds: [String] = demoLocations.map(\.id)
}
