//
//  OrderStatusDisplay.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

extension OrderStatus {
    var title: String {
        switch self {
        case .open: return "open"
        case .inProcess: return "inProcess"
        case .processed: return "processed"
        case .delivered: return "delivered"
        case .canceled: return "canceled"
        }
    }

    var color: Color {
        switch self {
        case .open: return Color.gray
        case .inProcess: return Color("inProcessColor")
        case .processed: return Color("processedColor")
        case .delivered: return Color.black
        case .canceled: return Color.orange
        }
    }

    var next: OrderStatus? {
        switch self {
        case .open: return .inProcess
        case .inProcess: return .processed
        case .processed: return .delivered
        case .delivered: return nil
        case .canceled: return nil
        }
    }
}
