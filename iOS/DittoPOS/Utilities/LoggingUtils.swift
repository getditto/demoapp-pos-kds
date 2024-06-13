///
//  LoggingUtils.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/19/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import OSLog
import Foundation

extension Logger {
    /// Use bundle identifier as the unique subsystem identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs eviction-related events
    static let eviction = Logger(subsystem: subsystem, category: "Eviction")

    /// All logs related to app launch
    static let app = Logger(subsystem: subsystem, category: "POS_app")
    
    /// Logs ditto service
    static let ditto = Logger(subsystem: subsystem, category: "Ditto")

    /// Logs  SyncService
    static let sync = Logger(subsystem: subsystem, category: "SyncService")

    /// Settings logging category
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    
    /// Logs relating to POS orders
    static let posOrders = Logger(subsystem: subsystem, category: "POSOrders")
    
    /// Logs relating to KDS orders
    static let kdsOrders = Logger(subsystem: subsystem, category: "KDSOrders")
    
    /// Catch-all logging category
    static let test = Logger(subsystem: subsystem, category: "TEST")
}
