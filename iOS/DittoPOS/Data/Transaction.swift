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
    let id: String
    var type: TransactionType
    var status: TransactionStatus
    var amount: Double
}
