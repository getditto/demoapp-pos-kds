//
//  SaleItemSeed.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

// Demo-only data.

import Foundation

enum SaleItemSeed {
    private struct Item {
        let id: String
        let name: String
        let imageName: String
        let cents: Int
    }

    private static let catalog: [Item] = [
        Item(id: "00001", name: "Burger",        imageName: "burger",       cents: 850),
        Item(id: "00002", name: "Burrito",       imageName: "burrito",      cents: 650),
        Item(id: "00003", name: "Fried Chicken", imageName: "chicken",      cents: 800),
        Item(id: "00004", name: "Potato Chips",  imageName: "chips",        cents: 250),
        Item(id: "00005", name: "Coffee",        imageName: "coffee",       cents: 195),
        Item(id: "00006", name: "Cookies",       imageName: "cookies",      cents: 350),
        Item(id: "00007", name: "Corn",          imageName: "corn",         cents: 350),
        Item(id: "00008", name: "French Fries",  imageName: "fries",        cents: 350),
        Item(id: "00009", name: "Fruit Salad",   imageName: "fruit_salad",  cents: 650),
        Item(id: "00010", name: "Gumbo",         imageName: "gumbo",        cents: 995),
        Item(id: "00011", name: "Ice Cream",     imageName: "ice_cream",    cents: 250),
        Item(id: "00012", name: "Milk",          imageName: "milk",         cents: 200),
        Item(id: "00013", name: "Onion Rings",   imageName: "onion_rings",  cents: 350),
        Item(id: "00014", name: "Pancakes",      imageName: "pancakes",     cents: 550),
        Item(id: "00015", name: "Pie",           imageName: "pie",          cents: 450),
        Item(id: "00016", name: "Salad",         imageName: "salad",        cents: 650),
        Item(id: "00017", name: "Sandwich",      imageName: "sandwich",     cents: 450),
        Item(id: "00018", name: "Soft Drink",    imageName: "soft_drink",   cents: 150),
        Item(id: "00019", name: "Tacos",         imageName: "tacos",        cents: 650),
        Item(id: "00020", name: "Veggie Plate",  imageName: "veggies",      cents: 750)
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
        var out: [SaleItem] = []
        for location in LocationSeed.demoLocations {
            for itemId in menus[location.id] ?? [] {
                guard let item = catalog.first(where: { $0.id == itemId }) else { continue }
                out.append(SaleItem.seed(
                    id: item.id,
                    locationId: location.id,
                    name: item.name,
                    imageName: item.imageName,
                    cents: item.cents
                ))
            }
        }
        return out
    }
}
