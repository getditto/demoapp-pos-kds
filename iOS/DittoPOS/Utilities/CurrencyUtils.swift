///
//  CurrencyUtils.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

// Whole-number minor units (cents for USD) avoids floating-point drift.
struct Price: Codable, Hashable, Equatable {
    var amount: Int
    var currency: Currency

    init(cents: Int, currency: Currency = .usd) {
        self.amount = cents
        self.currency = currency
    }

    init(dollars: Double, currency: Currency = .usd) {
        self.amount = Int((dollars * 100).rounded())
        self.currency = currency
    }
}

enum Currency: String, Codable {
    case chf
    case eur
    case gbp
    case usd
}

extension Price {
    var dollars: Double { Double(amount) / 100.0 }
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
        return formatter.string(from: NSNumber(value: dollars))!
    }
}

extension Double {
    func currencyFormatted() -> String {
        Price(dollars: self).description
    }
}
