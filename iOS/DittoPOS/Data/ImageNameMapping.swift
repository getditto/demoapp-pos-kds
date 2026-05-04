//
//  ImageNameMapping.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Maps the canonical wire imageName to the local iOS asset name.
enum ImageNameMapping {
    static let canonicalKeys: [String] = [
        "burger", "burrito", "chicken", "chips", "coffee", "cookies", "corn",
        "fries", "fruit_salad", "gumbo", "ice_cream", "milk", "onion_rings",
        "pancakes", "pie", "salad", "sandwich", "soft_drink", "tacos", "veggies"
    ]

    private static let canonicalToAsset: [String: String] = [
        "fruit_salad": "fruit-salad",
        "ice_cream": "ice-cream",
        "onion_rings": "onion-rings",
        "soft_drink": "soft-drink"
    ]

    static func assetName(for canonical: String) -> String {
        canonicalToAsset[canonical] ?? canonical
    }
}
