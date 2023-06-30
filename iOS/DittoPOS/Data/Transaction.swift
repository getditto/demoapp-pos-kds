///
//  Transaction.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

enum TransactionType: Int, Codable {
    case cash, credit, debit, refund
}

enum TransactionStatus: Int, Codable {
    case incomplete, inProcess, complete, failed
}

struct Transaction: Identifiable, Hashable, Equatable {
    let _id: [String: String]
    let createdOn: Date
    var type: TransactionType
    var status: TransactionStatus
    var amount: Double
    var id: String { _id["id"]! }
}

extension Transaction {
    static func new(
        locationId: String,
        orderId: String,
        createdOn: Date = Date(),
        type: TransactionType = .cash,
        status: TransactionStatus = .incomplete,
        amount: Double
    ) -> Transaction {
        Transaction(
            _id: Self._id(locId: locationId, orderId: orderId),
            createdOn: createdOn,
            type: type,
            status: status,
            amount: amount
        )
    }
    
    static func _id(locId: String, orderId: String) -> [String: String] {
        ["id": UUID().uuidString, "locationId": locId, "orderId": orderId]
    }
}
