///
//  UserDefaults+Extensions.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import DittoExportLogs
import Foundation

extension UserDefaults {
    public struct UserDefaultsKeys {
        static var loggingOption: String { "live.ditto.DittoPOS.loggingOption" }
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
        static var userKey: String { "live.ditto.DittoPOS.userKey" }
    }
    
    // stored location from both user-defined and default demo locations selection
    var storedLocationId: String? {
        get {
            return string(forKey: UserDefaultsKeys.currentLocationId)
        }
        set(value) {
            set(value, forKey: UserDefaultsKeys.currentLocationId)
        }
    }
    
    var storedSelectedTab: Int? {
        get {
            guard integer(forKey: UserDefaultsKeys.selectedTab) > 0 else { return nil }
            return integer(forKey: UserDefaultsKeys.selectedTab)
        }
        set(value) {
            set(value, forKey: UserDefaultsKeys.selectedTab)
        }
    }
    
    var storedLoggingOption: DittoLogger.LoggingOptions {
        get {
            let logOption = integer(forKey: UserDefaultsKeys.loggingOption)
            guard logOption != 0 else {
                return DittoLogger.LoggingOptions(rawValue: defaultLoggingOption.rawValue)!
            }
            return DittoLogger.LoggingOptions(rawValue: logOption)!
        }
        set(value) {
            set(value.rawValue, forKey: UserDefaultsKeys.loggingOption)
        }
    }
}

// use case: user-defined location
extension UserDefaults {
    @objc dynamic var userData: Data? {
        get { UserDefaults.standard.data(forKey: UserDefaultsKeys.userKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.userKey) }
    }

    var userDataPublisher: AnyPublisher<Data?, Never> {
        UserDefaults.standard
            .publisher(for: \.userData)
            .eraseToAnyPublisher()
    }
}
