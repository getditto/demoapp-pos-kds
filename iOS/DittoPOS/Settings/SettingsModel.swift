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
import OSLog

struct Settings {
    static var defaults = UserDefaults.standard
    
    static var dittoLoggingOption: DittoLogger.LoggingOptions {
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
        static var loggingOption: String { "live.ditto.DittoPOS.loggingOption" }
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
        //rename: keep legacy "userKey" key
        static var customLocationKey: String { "live.ditto.DittoPOS.userKey" }
        static var useDemoLocations: String { "live.ditto.DittoPOS.useDemoLocations" }
        
        static var deviceId: String {"live.ditto.DittoPOS.deviceId"}
        
        static var lastEvictionDate      = "live.ditto.eviction.lastEvictionDate"
        static var evictionLogs          = "live.ditto.eviction.logs"
        static var usePublishedAppConfig = "live.ditto.usePublishedAppConfig"
        static var localAppConfig        = "live.ditto.localAppConfig"
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


//--------------------------------------------------------------------------------
//MARK:  AppConfig/Eviction
//--------------------------------------------------------------------------------
extension Settings {
    
    // AppConfig
    static var usePublishedAppConfig: Bool {
        get { defaults.usePublishedAppConfig }
        set(value) { defaults.usePublishedAppConfig = value }
    }
    
    static var storedAppConfig: AppConfig? {
        get { try? JSONDecoder().decode(AppConfig.self, from: defaults.storedAppConfig ?? Data()) }
        set { try? defaults.storedAppConfig = JSONEncoder().encode(newValue) }
    }
    static var storedAppConfigPublisher: AnyPublisher<AppConfig?, Never> {
        get {
            defaults.storedAppConfigPublisher
                .map {
                    try? JSONDecoder().decode(AppConfig.self, from: $0 ?? Data())
                }
                .eraseToAnyPublisher()
        }
    }
    
    //Eviction
    static var lastEvictionDate: Date? {
        get { defaults.lastEvictionDate }
        set { defaults.lastEvictionDate = newValue }
    }

    static var evictionLogs: [EvictionLog]? {
        get {
            guard let logsData = defaults.evictionLogs else {
                Logger.eviction.warning("SM.\(#function,privacy:.public): no existing logs data (first access?) --> Return NIL")
                return nil
            }
            do {
                let logs = try JSONDecoder().decode([EvictionLog].self, from: logsData)
                return logs
            } catch {
                Logger.eviction.error("SM.\(#function,privacy:.public): ERROR accessing logs:\n \(error.localizedDescription,privacy:.public)")
            }
            return nil
        }
        set {
            do {
                try defaults.evictionLogs = JSONEncoder().encode(newValue)
            } catch {
                Logger.eviction.error("SM.\(#function,privacy:.public): ERROR writing logs:\n \(error.localizedDescription,privacy:.public)")
            }
        }
    }
    static var evictionLogsPublisher: AnyPublisher<[EvictionLog]?, Never> {
        get {
            defaults.evictionLogsPublisher
                .map {
                    try? JSONDecoder().decode([EvictionLog].self, from: $0 ?? Data())
                }
                .eraseToAnyPublisher()
        }
    }
    
//    static var ordersSubscribeTTL: TimeInterval {
//        get { defaults.ordersSubscribeTTL }
//        set { defaults.ordersSubscribeTTL = newValue }
//    }
}


//let defaultEvictionInterval   = TimeInterval(360)     //<- (6 min TEST) //TimeInterval(60 * 60 * 24)     // 24 hours
//let defaultEvictionInterval   = TimeInterval(60 * 60 * 24)  // 24 hours (now defined in appConfig)
//let defaultOrdersEvictTTL     = TimeInterval(3600 * 3) //<- (3 hrs TEST) //TimeInterval(60 * 60 * 24 * 7) //  7 days
//let defaultOrdersEvictTTL     = TimeInterval(60 * 3)   //<- (3 minutes TEST) //TimeInterval(60 * 60 * 24 * 7) //  7 days
//let defaultOrdersSubscribeTTL = TimeInterval(60 * 60 * 24) //TEST <- 2hrs  //TimeInterval(3600) //<- (1 hr TEST) //TimeInterval(60 * 60 * 24)     // 24 hours
//appConfig: 24 subscription TTL - while testing, eviction should run far more often
//let defaultOrdersSubscribeTTL = TimeInterval(60 * 60 * 24) // 24 hours
extension UserDefaults {
    
    // AppConfig
    @objc dynamic var usePublishedAppConfig: Bool {
        get { return bool(forKey: UserDefaultsKeys.usePublishedAppConfig) }
        set(value) { set(value, forKey: UserDefaultsKeys.usePublishedAppConfig) }
    }
    var usePublishedAppConfigPublisher: AnyPublisher<Bool, Never> {
        UserDefaults.standard
            .publisher(for: \.usePublishedAppConfig)
            .eraseToAnyPublisher()
    }

    var storedAppConfig: Data? {
        get { data(forKey: UserDefaultsKeys.localAppConfig) }
        set(value) { set(value, forKey: UserDefaultsKeys.localAppConfig) }
    }
    var storedAppConfigPublisher: AnyPublisher<Data?, Never> {
        UserDefaults.standard
            .publisher(for: \.storedAppConfig)
            .eraseToAnyPublisher()
    }

    // Eviction
    var lastEvictionDate: Date? {
        get { object(forKey: UserDefaultsKeys.lastEvictionDate) as? Date }
        set(value) { set(value, forKey: UserDefaultsKeys.lastEvictionDate) }
    }

    @objc dynamic var evictionLogs: Data? {
        get { data(forKey: UserDefaultsKeys.evictionLogs) }
        set(value) { set(value, forKey: UserDefaultsKeys.evictionLogs) }
    }
    var evictionLogsPublisher: AnyPublisher<Data?, Never> {
        UserDefaults.standard
            .publisher(for: \.evictionLogs)
            .eraseToAnyPublisher()
    }

//    var ordersEvictTTL: TimeInterval {
//        get {
//            let interval = double(forKey: Keys.ordersEvictTTL)
//            return interval == 0.0 ? defaultOrdersEvictTTL : interval
//        }
//        set(value) { set(value, forKey: Keys.ordersEvictTTL) }
//    }

//    var ordersSubscribeTTL: TimeInterval {
//        get {
//            let interval = double(forKey: Keys.ordersSubscribeTTL)
//            return interval == 0.0 ? defaultOrdersSubscribeTTL : interval
//        }
//        set(value) { set(value, forKey: Keys.ordersSubscribeTTL) }
//    }

//    var evictionInterval: TimeInterval {
//        get {
//            let interval = double(forKey: Keys.evictionInterval)
//            return interval == 0.0 ? defaultEvictionInterval : interval
//        }
//        set(value) { set(value, forKey: Keys.evictionInterval) }
//    }
}
