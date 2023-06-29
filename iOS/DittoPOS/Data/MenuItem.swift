///
//  MenuItem.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

struct MenuItem: Identifiable {
    let id: String
    let title: String
    let imageName: String
    var imageToken: DittoAttachmentToken?
    let price: Price
}

extension MenuItem {
    init(doc: DittoDocument) {
        self.id = doc["_id"].stringValue
        self.title = doc["title"].stringValue
        self.imageName = doc["imageName"].string ?? "ellipsis"
        self.imageToken = doc["imageToken"].attachmentToken
        self.price = Price(doc["price"].doubleValue)
    }
}

extension MenuItem: Equatable {
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension MenuItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MenuItem: CustomStringConvertible {
    var description: String {
        "\(title): \(price.description)"
    }
}

extension MenuItem {
    static var demoItems: [MenuItem] {
        [
            MenuItem(id: "00001", title: "Burger", imageName: "burger", price: Price( 8.50)),
            MenuItem(id: "00002", title: "Burrito", imageName: "burrito", price: Price( 6.50)),
            MenuItem(id: "00003", title: "Fried Chicken", imageName: "chicken", price: Price( 8.00)),
            MenuItem(id: "00004", title: "Potato Chips", imageName: "chips", price: Price( 2.50)),
            MenuItem(id: "00005", title: "Coffee", imageName: "coffee", price: Price( 1.95)),
            MenuItem(id: "00006", title: "Cookies", imageName: "cookies", price: Price( 3.50)),
            MenuItem(id: "00007", title: "Corn", imageName: "corn", price: Price( 3.50)),
            MenuItem(id: "00008", title: "French Fries", imageName: "fries", price: Price( 3.50)),
            MenuItem(id: "00009", title: "Fruit Salad", imageName: "fruit-salad", price: Price( 6.50)),
            MenuItem(id: "00010", title: "Gumbo", imageName: "gumbo", price: Price( 9.95)),
            MenuItem(id: "00011", title: "Ice Cream", imageName: "ice-cream", price: Price( 2.50)),
            MenuItem(id: "00012", title: "Milk", imageName: "milk", price: Price( 2.00)),
            MenuItem(id: "00013", title: "Onion Rings", imageName: "onion-rings", price: Price( 3.50)),
            MenuItem(id: "00014", title: "Pancakes", imageName: "pancakes", price: Price( 5.50)),
            MenuItem(id: "00015", title: "Pie", imageName: "pie", price: Price( 4.50)),
            MenuItem(id: "00016", title: "Salad", imageName: "salad", price: Price( 6.50)),
            MenuItem(id: "00017", title: "Sandwich", imageName: "sandwich", price: Price( 4.50)),
            MenuItem(id: "00018", title: "Soft Drink", imageName: "soft-drink", price: Price( 1.50)),
            MenuItem(id: "00019", title: "Tacos", imageName: "tacos", price: Price( 6.50)),
            MenuItem(id: "00020", title: "Veggie Plate", imageName: "veggies", price: Price( 7.50))
        ]
    }
}
