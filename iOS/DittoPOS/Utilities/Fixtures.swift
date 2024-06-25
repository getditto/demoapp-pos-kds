//
//  Fixtures.swift
//  DittoPOS
//
//  Created by Erik Everson on 1/31/24.
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Foundation

enum Fixtures {
    static let kdsVM = KDS_VM(previewOrders: [order1, order1])
    static let order1 = Order(_id: ["locationld" : "Test lab-Denver", "id" : "116BE13B-2FB3-4593-9CE7-2823504A27C6"],
                                     deviceId: "4785314265459795039",
                                     saleItemIds: ["04160E1B-D9E1-4560-8B6E-244F6AF19C25_2024-01-31T15:55:13.151Z": "00001", "03A5A57E-99C3-4C64-A675-BEC5BA5CC3C0_2024-01-31T15:55:12.541Z": "00008"],
                              transactionIds: ["3B3B5FB4-0D40-492F-8AC0-D025D4506E25": .inProcess],
                              orderItems: [orderItem1, orderItem2],
                              createdOn: date,
                              status: .inProcess)
    static let orderItem1 = OrderItem(id: "04160E1B-D9E1-4560-8B6E-244F6AF19C25_2024-01-31T15:55:13.151Z", saleItem: salesItem1, createdOnStr: createdOnStr, createdOn: date)
    static let salesItem1 = SaleItem.new(id: "00001", title: "Burger", imageName: "burger", price: Price( 8.50))
    static let orderItem2 = OrderItem(id: "003A5A57E-99C3-4C64-A675-BEC5BA5CC3C0_2024-01-31T15:55:12.541Z", saleItem: salesItem2, createdOnStr: createdOnStr, createdOn: date)
    static let salesItem2 = SaleItem.new(id: "00008", title: "French Fries", imageName: "fries", price: Price( 3.50))
    static let createdOnStr = DateFormatter.isoDate.string(from: date)
    static let date = Date.now
}
