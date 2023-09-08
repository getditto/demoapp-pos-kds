///
//  UserDefaults+Extensions.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift
import DittoExportLogs
import Foundation

extension UserDefaults {
    public enum UserDefaultsKeys: String {
        case loggingOption = "live.ditto.DittoPOS.loggingOption"
        case currentLocationId = "live.ditto.DittoPOS.currentLocationId"
        case selectedTab = "live.ditto.DittoPOS.selectedTab"
    }
    
    var storedLocationId: String? {
        get {
            return string(forKey: UserDefaultsKeys.currentLocationId.rawValue)
        }
        set(value) {
            set(value, forKey: UserDefaultsKeys.currentLocationId.rawValue)
        }
    }
    
    var storedSelectedTab: Int? {
        get {
            guard integer(forKey: UserDefaultsKeys.selectedTab.rawValue) > 0 else { return nil }
            return integer(forKey: UserDefaultsKeys.selectedTab.rawValue)
        }
        set(value) {
            set(value, forKey: UserDefaultsKeys.selectedTab.rawValue)
        }
    }
    
    var storedLoggingOption: DittoLogger.LoggingOptions {
        get {
            let logOption = integer(forKey: UserDefaultsKeys.loggingOption.rawValue)
            guard logOption != 0 else {
                return DittoLogger.LoggingOptions(rawValue: defaultLoggingOption.rawValue)!
            }
            return DittoLogger.LoggingOptions(rawValue: logOption)!
        }
        set(value) {
            set(value.rawValue, forKey: UserDefaultsKeys.loggingOption.rawValue)
        }
    }
}
