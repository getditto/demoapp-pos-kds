///
//  UserDefaults+Extensions.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/21/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Foundation

extension UserDefaults {
    
    var storedLocationId: String? {
        get {
            return string(forKey: "ditto.currentLocationId")
        }
        set(value) {
            set(value, forKey: "ditto.currentLocationId")
        }
    }
    
    var storedSelectedTab: Int? {
        get {
            return integer(forKey: "ditto.selectedTab")
        }
        set(value) {
            set(value, forKey: "ditto.selectedTab")
        }
    }
    /*
    var storedLocation: Location? {
        get {
            guard let jsonData = object(forKey: "ditto.currentLocation") as? Data else { return nil }
            return decodeObjFromData(jsonData)
        }
        set(value) {
            if let loc = value {
               if let jsonData = encodedObject(loc) {
                    set(jsonData, forKey: "ditto.currentLocation")
               } else { print("storedLocation JSON encoding failed") }
            } else {
                UserDefaults.standard.removeObject(forKey: "ditto.currentLocation")
            }
        }
    }
    
    var currentOrder: Order? {
        get {
            guard let jsonData = object(forKey: "ditto.currentOrder") as? Data else { return nil }
            return decodeObjFromData(jsonData)
        }
        set(value) {
            if let order = value, let jsonData = encodedObject(order) {
                set(jsonData, forKey: "ditto.currentOrder")
            }
        }
    }
    
    private func encodedObject<T: Codable>(_ obj: T) -> Data? {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(obj) else {
            print("UserDefaults.\(#function): ERROR encoding \(T.self)")
            return nil
        }
        return jsonData
    }

    private func decodeObjFromData<T: Codable>(_ jsonData: Data) -> T? {
        let decoder = JSONDecoder()
        guard let obj = try? decoder.decode(T.self, from: jsonData) else {
            print("UserDefaults.\(#function): ERROR decoding type: \(T.self) from json data")
            return nil
        }
        return obj
    }
     */
}
