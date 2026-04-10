///
//  SettingsModel.swift
//  DittoPOS
//
//  Created by Eric Turner on 3/8/24.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import Foundation

struct Settings {
    static var defaults = UserDefaults.standard

    static var locationId: String? {
        get { defaults.storedLocationId }
        set(value) { defaults.storedLocationId = value }
    }

    static var selectedTabView: TabViews? {
        get { defaults.selectedTabView }
        set(value) { defaults.selectedTabView = value }
    }
    static var selectedTabViewPublisher: AnyPublisher<TabViews?, Never> { defaults.selectedTabViewPublisher }

    // For testing only
    static func clearLocationsSetup() {
        locationId = nil
    }
}

extension UserDefaults {
    public struct UserDefaultsKeys {
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
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
