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
    
    static var dittoLoggingOption: DittoLogLevel {
        get { defaults.storedLoggingOption }
        set(value) { defaults.storedLoggingOption = value }
    }
    
    static var deviceId: String {
        get { defaults.storedDeviceId }
        set(value) { defaults.storedDeviceId = value }
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
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
        //rename: keep legacy "userKey" key
        static var customLocationKey: String { "live.ditto.DittoPOS.userKey" }
        static var useDemoLocations: String { "live.ditto.DittoPOS.useDemoLocations" }
        
        static var deviceId: String {"live.ditto.DittoPOS.deviceId"}
    }
    
    var storedDeviceId: String {
        get {
            if let deviceId = string(forKey: UserDefaultsKeys.deviceId) {
                return deviceId
            } else {
                //demo purposes only. User should set deviceId from a persistant unique Id, usually from an MDM.
                let newDeviceId = UUID().uuidString
                set(newDeviceId, forKey: UserDefaultsKeys.deviceId)
                return newDeviceId
            }
        }
        set(value) {
            set(value, forKey: UserDefaultsKeys.deviceId)
        }
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
    
    var storedLoggingOption: DittoLogLevel {
        get {
            /// Migrates the stored logging option from the legacy key to the new system.
            ///
            /// This function checks if a value exists under the legacy key (`"live.ditto.DittoPOS.loggingOption"`) in `UserDefaults`.
            /// If a non-zero value is found, it is manually mapped to the appropriate `DittoLogLevel`
            /// and stored using the new storage mechanism. The legacy key is removed after migration
            /// to ensure it is no longer used.
            ///
            /// - Important: This function must be called before accessing or restoring the current logging option
            /// to ensure any legacy values are migrated correctly.
            func migrateFromLegacyStorage() {
                let oldKey = "live.ditto.DittoPOS.loggingOption"
                
                // Check if a value exists for the old key
                guard object(forKey: oldKey) != nil else { return }
                
                // Retrieve the integer value stored with the legacy key
                let rawValue = integer(forKey: oldKey)
                
                // Manually map legacy values to the correct DittoLogLevel
                let mappedLogLevel: DittoLogLevel?
                switch rawValue {
                case 0:
                    mappedLogLevel = nil  // 0 indicates no logging, skip migration
                case 1:
                    mappedLogLevel = .error
                case 2:
                    mappedLogLevel = .warning
                case 3:
                    mappedLogLevel = .info
                case 4:
                    mappedLogLevel = .debug
                default:
                    mappedLogLevel = nil  // Unknown values, skip migration
                }
                
                // Save the mapped value if valid
                if let logLevel = mappedLogLevel {
                    logLevel.saveToStorage()
                }
                
                // Remove the old key
                removeObject(forKey: oldKey)
            }
            
            // Perform migration before restoring the value
            migrateFromLegacyStorage()
            
            // Restore the log level from storage, defaulting to `.error` if no value is found
            return DittoLogLevel.restoreFromStorage()
        }
        set {
            // Save the new log level to storage
            newValue.saveToStorage()
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
