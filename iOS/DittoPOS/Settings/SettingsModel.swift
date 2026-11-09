//
//  SettingsModel.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

enum TabViews: Int, Identifiable {
    case pos=1, kds, settings
    var id: Self { self }
}

@MainActor struct Settings {
    static var defaults = UserDefaults.standard

    static var locationId: String? {
        get { defaults.storedLocationId }
        set(value) { defaults.storedLocationId = value }
    }

    static var selectedTabView: TabViews? {
        get { defaults.selectedTabView }
        set(value) { defaults.selectedTabView = value }
    }

}

extension UserDefaults {
    public struct UserDefaultsKeys {
        static var currentLocationId: String { "live.ditto.DittoPOS.currentLocationId" }
        static var selectedTab: String { "live.ditto.DittoPOS.selectedTab" }
    }

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

    @MainActor var selectedTabView: TabViews? {
        get {
            let tabInt = integer(forKey: UserDefaultsKeys.selectedTab)
            return tabInt == 0 ? nil : TabViews(rawValue: tabInt)
        }
        set(newValue) {
            let tabInt = newValue?.rawValue ?? 0
            set(tabInt, forKey: UserDefaultsKeys.selectedTab)
        }
    }
}
