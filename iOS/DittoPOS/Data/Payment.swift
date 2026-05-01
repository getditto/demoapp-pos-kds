//
//  Payment.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

enum PaymentType: String, Codable, CaseIterable {
    case cash, credit, debit, refund
}

enum PaymentStatus: String, Codable, CaseIterable {
    case incomplete, inProcess, complete, failed
}

struct Payment: Codable, Hashable, Equatable {
    let type: PaymentType
    let amount: Price
    let status: PaymentStatus
    let createdOn: Date

    init(
        type: PaymentType,
        amount: Price,
        status: PaymentStatus = .complete,
        createdOn: Date = Date()
    ) {
        self.type = type
        self.amount = amount
        self.status = status
        self.createdOn = createdOn
    }

    static func newPaymentId() -> String { UUID().uuidString }
}
