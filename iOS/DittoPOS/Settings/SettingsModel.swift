///
//  SettingsModel.swift
//  DittoPOS
//
//  Created by Eric Turner on 3/8/24.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import DittoExportLogs
import Foundation

struct Settings {
    static var defaults = UserDefaults.standard
    
    static var dittoLoggingOption: DittoLogger.LoggingOptions {
        get { defaults.storedLoggingOption }
        set(value) { defaults.storedLoggingOption = value }
    }
    
    static var locationId: String? {
        get { defaults.storedLocationId }
        set(value) { defaults.storedLocationId = value }
    }
    
    static var selectedTabView: TabViews? {
        get { defaults.selectedTabView }
        set(value) { defaults.selectedTabView = value }
    }
    static var selectedTabViewPublisher: AnyPublisher<TabViews?, Never> { defaults.selectedTabViewPublisher }
    
    static var useDemoLocations: Bool {
        get { defaults.storedUseDemoLocations }
        set(value) { defaults.storedUseDemoLocations = value }
    }
    static var useDemoLocationsPublisher: AnyPublisher<Bool, Never> { defaults.useDemoLocationsPublisher }
    
    static var customLocation: Data? {
        get { defaults.storedCustomLocation }
        set(value) { defaults.storedCustomLocation = value }
    }
    static var customLocationPublisher: AnyPublisher<Data?, Never> { defaults.customLocationPublisher }
    
    // For testing only
    static func clearLocationsSetup() {
        useDemoLocations = false
        customLocation = nil
        locationId = nil
    }

}

// MARK: Observability data
extension Settings {
    
    static private var _metaData: [String:Any] = [:]
    
    static private var _isHeartbeatOn: Bool = false
    static private var _secondsInterval: Int = 30
    
    static var metaData: [String:Any] {
        get { _metaData }
        set (value) { _metaData = value }
    }
    
    static var isHeartbeatOn: Bool {
        get { _isHeartbeatOn }
        set (value) { _isHeartbeatOn = value }
    }
    
    static var secondsInterval: Int {
        get { _secondsInterval }
        set (value) { _secondsInterval = value }
    }
}


extension UserDefaults {
    public struct UserDefaultsKeys {
        static var loggingOption: String { "live.ditto.DittoPOS.loggingOption" }
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
        //rename: keep legacy "userKey" key
        static var customLocationKey: String { "live.ditto.DittoPOS.userKey" }
        static var useDemoLocations: String { "live.ditto.DittoPOS.useDemoLocations" }
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

// use case: switch between demo locations and user-defined
extension UserDefaults {
    @objc dynamic var storedUseDemoLocations: Bool {
        get { return bool(forKey: UserDefaultsKeys.useDemoLocations) }
        set(value) { set(value, forKey: UserDefaultsKeys.useDemoLocations) }
    }
    
    var useDemoLocationsPublisher: AnyPublisher<Bool, Never> {
        UserDefaults.standard
            .publisher(for: \.storedUseDemoLocations)
            .eraseToAnyPublisher()
    }
}

// use case: user-defined location
extension UserDefaults {
    @objc dynamic var storedCustomLocation: Data? {
        get { UserDefaults.standard.data(forKey: UserDefaultsKeys.customLocationKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.customLocationKey) }
    }

    var customLocationPublisher: AnyPublisher<Data?, Never> {
        UserDefaults.standard
            .publisher(for: \.storedCustomLocation)
            .eraseToAnyPublisher()
    }
}

extension UserDefaults {

    var selectedTabView: TabViews? {
        get {
            let tabInt = Self.standard.integer(forKey: UserDefaultsKeys.selectedTab)
            return tabInt == 0 ? nil : TabViews(rawValue: tabInt)
        }
        set(newValue) {
            let tabInt = newValue?.rawValue ?? 0
            set(tabInt, forKey: UserDefaultsKeys.selectedTab)
            
            let retTab = newValue == nil ? nil : TabViews(rawValue: tabInt)
            Self.selectedTabSubject.send(retTab)
        }
    }
        
    // Workaround for UserDefaults does not support publishing optional Int natively, so to implement
    // selectedTabViewPublisher, we have to be notified when selectedTabView is updated (above).
    private static var selectedTabSubject = PassthroughSubject<TabViews?, Never>()
    
    var selectedTabViewPublisher: AnyPublisher<TabViews?, Never> {
        Self.selectedTabSubject
            .eraseToAnyPublisher()
    }
}
