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

enum TransactionStatus: Int, CaseIterable, Codable {
    case incomplete, inProcess, complete, failed
}

struct Transaction: Identifiable, Hashable, Equatable {
    let _id: [String: String]
    let createdOn: Date
    var type: TransactionType
    var status: TransactionStatus
    var amount: Double
    var id: String { _id["id"]! }

    static let collectionName = "transactions"
}

extension Transaction {
    static func new(
        locationId: String,
        orderId: String,
        createdOn: Date = Date(),
        type: TransactionType = .cash,
        status: TransactionStatus = .complete, // default all new transactions to .complete, at least for now
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

// MARK: - Query
extension Transaction {
    var insertNewQuery: DittoQuery {
        (
            string: """
                INSERT INTO \(Self.collectionName)
                DOCUMENTS (:new)
                ON ID CONFLICT DO UPDATE
            """,
            args: [
                "new":
                    [
                        "_id": _id,
                        "createdOn": createdOn,
                        "type": type,
                        "status": status,
                        "amount": amount
                    ]
            ]
        )
    }
}
