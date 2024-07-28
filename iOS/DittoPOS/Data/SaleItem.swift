///
//  SaleItem.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

struct SaleItem: Codable {
    let _id: [String: String] // [id: String, locationId: String]
    let title: String
    let imageName: String // this should be temporary in favor of imageToken
    let price: Price
}

extension SaleItem: Identifiable {
    var id: String { _id["id"]! }
    var locationId: String { _id["locationId"]! }
}

extension SaleItem: Equatable {
    static func == (lhs: SaleItem, rhs: SaleItem) -> Bool {
        lhs._id == rhs._id
    }
}

extension SaleItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(_id)
    }
}

extension SaleItem: CustomStringConvertible {
    var description: String {
        "\(title): \(price.description)"
    }
}

extension SaleItem {
    static func new(
        id: String,
        locationId: String = "0",
        title: String,
        imageName: String,
        price: Price
    ) -> SaleItem {
        SaleItem(
            _id: Self.newId(id: id, locId: locationId),
            title: title,
            imageName: imageName,
            price: price
        )
    }
    
    static func newId(id: String, locId: String) -> [String: String] {
        ["id": id, "locationId": locId]
    }
}

// MARK: - Demo dummy data
extension SaleItem {
    static var demoItems: [SaleItem] {
        [
            SaleItem.new(id: "00001", title: "Big Mac", imageName: "big_mac", price: Price(8.50)),
                SaleItem.new(id: "00002", title: "Quarter Pounder with Cheese", imageName: "quarter_pounder_cheese", price: Price(9.00)),
                SaleItem.new(id: "00003", title: "McChicken", imageName: "mcchicken", price: Price(6.75)),
                SaleItem.new(id: "00004", title: "Filet-O-Fish", imageName: "filet_o_fish", price: Price(7.25)),
                SaleItem.new(id: "00005", title: "Chicken McNuggets", imageName: "chicken_mcnuggets", price: Price(7.99)),
                SaleItem.new(id: "00006", title: "McDouble", imageName: "mcdouble", price: Price(4.50)),
                SaleItem.new(id: "00007", title: "French Fries", imageName: "fries", price: Price(3.50)),
                SaleItem.new(id: "00008", title: "Apple Pie", imageName: "apple_pie", price: Price(2.50)),
                SaleItem.new(id: "00009", title: "Oreo McFlurry", imageName: "mcflurry_oreo", price: Price(4.00)),
                SaleItem.new(id: "00010", title: "Coca-Cola (Large)", imageName: "soft-drink", price: Price(2.75)),
            SaleItem.new(id: "00010", title: "Coca-Cola (Large)", imageName: "soft-drink", price: Price(2.75)),
            SaleItem.new(id: "00010", title: "Coca-Cola (Large)", imageName: "soft-drink", price: Price(2.75))
//            SaleItem.new(id: "00001", title: "Burger", imageName: "burger", price: Price( 8.50)),
//            SaleItem.new(id: "00002", title: "Burrito", imageName: "burrito", price: Price( 6.50)),
//            SaleItem.new(id: "00003", title: "Fried Chicken", imageName: "chicken", price: Price( 8.00)),
//            SaleItem.new(id: "00004", title: "Potato Chips", imageName: "chips", price: Price( 2.50)),
//            SaleItem.new(id: "00005", title: "Coffee", imageName: "coffee", price: Price( 1.95)),
//            SaleItem.new(id: "00006", title: "Cookies", imageName: "cookies", price: Price( 3.50)),
//            SaleItem.new(id: "00007", title: "Corn", imageName: "corn", price: Price( 3.50)),
//            SaleItem.new(id: "00008", title: "French Fries", imageName: "fries", price: Price( 3.50)),
//            SaleItem.new(id: "00009", title: "Fruit Salad", imageName: "fruit-salad", price: Price( 6.50)),
//            SaleItem.new(id: "00010", title: "Gumbo", imageName: "gumbo", price: Price( 9.95)),
//            SaleItem.new(id: "00011", title: "Ice Cream", imageName: "ice-cream", price: Price( 2.50)),
//            SaleItem.new(id: "00012", title: "Milk", imageName: "milk", price: Price( 2.00)),
//            SaleItem.new(id: "00013", title: "Onion Rings", imageName: "onion-rings", price: Price( 3.50)),
//            SaleItem.new(id: "00014", title: "Pancakes", imageName: "pancakes", price: Price( 5.50)),
//            SaleItem.new(id: "00015", title: "Pie", imageName: "pie", price: Price( 4.50)),
//            SaleItem.new(id: "00016", title: "Salad", imageName: "salad", price: Price( 6.50)),
//            SaleItem.new(id: "00017", title: "Sandwich", imageName: "sandwich", price: Price( 4.50)),
//            SaleItem.new(id: "00018", title: "Soft Drink", imageName: "soft-drink", price: Price( 1.50)),
//            SaleItem.new(id: "00019", title: "Tacos", imageName: "tacos", price: Price( 6.50)),
//            SaleItem.new(id: "00020", title: "Veggie Plate", imageName: "veggies", price: Price( 7.50))
        ]
    }
}
