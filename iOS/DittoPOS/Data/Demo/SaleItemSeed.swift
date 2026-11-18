//
//  SaleItemSeed.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// Demo-only data.

import Foundation

enum SaleItemSeed {
    static let initialQuantity: Int64 = 20

    private struct Item {
        let id: String
        let name: String
        let cents: Int
    }

    private static let catalog: [Item] = [
        Item(id: "00001", name: "Burger",        cents: 850),
        Item(id: "00002", name: "Burrito",       cents: 650),
        Item(id: "00003", name: "Fried Chicken", cents: 800),
        Item(id: "00004", name: "Potato Chips",  cents: 250),
        Item(id: "00005", name: "Coffee",        cents: 195),
        Item(id: "00006", name: "Cookies",       cents: 350),
        Item(id: "00007", name: "Corn",          cents: 350),
        Item(id: "00008", name: "French Fries",  cents: 350),
        Item(id: "00009", name: "Fruit Salad",   cents: 650),
        Item(id: "00010", name: "Gumbo",         cents: 995),
        Item(id: "00011", name: "Ice Cream",     cents: 250),
        Item(id: "00012", name: "Milk",          cents: 200),
        Item(id: "00013", name: "Onion Rings",   cents: 350),
        Item(id: "00014", name: "Pancakes",      cents: 550),
        Item(id: "00015", name: "Pie",           cents: 450),
        Item(id: "00016", name: "Salad",         cents: 650),
        Item(id: "00017", name: "Sandwich",      cents: 450),
        Item(id: "00018", name: "Soft Drink",    cents: 150),
        Item(id: "00019", name: "Tacos",         cents: 650),
        Item(id: "00020", name: "Veggie Plate",  cents: 750)
    ]

    private static let menus: [String: [String]] = [
        "00001": ["00001", "00008", "00013", "00018", "00012", "00011", "00006"],            // Ham's: burger/fries/onion rings/soda/milk/ice cream/cookies
        "00002": ["00016", "00009", "00020", "00017", "00018", "00005", "00012"],            // Sally's: salad/fruit salad/veggies/sandwich/soda/coffee/milk
        "00003": ["00003", "00017", "00016", "00020", "00018", "00005", "00006"],            // Kyle's: chicken/sandwich/salad/veggies/soda/coffee/cookies
        "00004": ["00017", "00016", "00020", "00009", "00018", "00005", "00015"],            // Frank's: sandwich/salad/veggies/fruit salad/soda/coffee/pie
        "00005": ["00014", "00009", "00005", "00012", "00011", "00015", "00006"],            // Cathy's: pancakes/fruit salad/coffee/milk/ice cream/pie/cookies
        "00006": ["00010", "00017", "00007", "00018", "00012", "00015"],                     // Gilbert's: gumbo/sandwich/corn/soda/milk/pie
        "00007": ["00019", "00002", "00007", "00018", "00003", "00011"]                      // Tarra's: tacos/burrito/corn/soda/chicken/ice cream
    ]

    static func saleItemsForAllLocations() -> [SaleItem] {
        let byId = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        return LocationSeed.demoLocations.flatMap { location in
            menus[location.id]!.map { itemId in
                let item = byId[itemId]!
                return SaleItem(
                    documentId: DocumentID(id: item.id, locationId: location.id),
                    name: item.name,
                    price: Price(cents: item.cents),
                    quantity: initialQuantity
                )
            }
        }
    }
}
