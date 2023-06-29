///
//  CurrencyUtils.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

// https://swiftbysundell.com/articles/formatting-numbers-in-swift/

struct Price: Codable {
    var amount: Double
    var currency: Currency
    init(_ amt: Double, currency: Currency = .usd) {
        self.amount = amt
        self.currency = currency
    }
}

enum Currency: String, Codable {
    case chf
    case eur
    case gbp
    case usd
}

extension Price: CustomStringConvertible {
    static var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }

    var description: String {
        let formatter = Self.formatter
        formatter.currencyCode = currency.rawValue
        let number = NSNumber(value: amount)
        return formatter.string(from: number)!
    }
}

extension Double {
    func toCurrency() -> String {
        Price(self).description
    }
}
