//
//  Fixtures.swift
//  DittoPOS
//
//  Created by Erik Everson on 1/31/24.
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Foundation

// Preview-only fixtures. Seed data lives in Data/Demo/.
enum Fixtures {
    static let kdsVM = KDS_VM(previewOrders: [order1, order1])

    static let date = Date.now
    static let createdAtStr = DateFormatter.isoDate.string(from: date)
    static let statusEntry = StatusLogDerivation.entry(.inProcess, at: date)

    static let salesItem1 = SaleItem.seed(id: "00001", locationId: "Test lab-Denver", name: "Burger", imageName: "burger", cents: 850)
    static let salesItem2 = SaleItem.seed(id: "00008", locationId: "Test lab-Denver", name: "French Fries", imageName: "fries", cents: 350)

    static let lineItem1 = CartLineItem(from: salesItem1)
    static let lineItem2 = CartLineItem(from: salesItem2)

    static let order1 = Order(
        _id: DocumentID(id: "116BE13B-2FB3-4593-9CE7-2823504A27C6", locationId: "Test lab-Denver"),
        cart: [
            "04160E1B-D9E1-4560-8B6E-244F6AF19C25": lineItem1,
            "03A5A57E-99C3-4C64-A675-BEC5BA5CC3C0": lineItem2
        ],
        payments: [:],
        statusLog: [statusEntry.key: statusEntry.value],
        createdAt: date
    )
}
