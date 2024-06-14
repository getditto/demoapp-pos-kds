///
//  AppConfig.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/30/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Foundation


struct EvictionPolicy: CustomStringConvertible {
    var noEvictPeriodStartSeconds: TimeInterval //seconds from midnight
    var noEvictPeriodEndSeconds: TimeInterval   //seconds from midnight
    
    init(noEvictPeriodStartSeconds: TimeInterval, noEvictPeriodEndSeconds: TimeInterval) {
        self.noEvictPeriodStartSeconds = noEvictPeriodStartSeconds
        self.noEvictPeriodEndSeconds = noEvictPeriodEndSeconds
    }
    init() {
        noEvictPeriodStartSeconds = TimeInterval(0.0)
        noEvictPeriodEndSeconds  = TimeInterval(0.0)
    }
    init(value: [String:Any?]) {
        if let start = value["noEvictPeriodStartSeconds"] as? Float {
            noEvictPeriodStartSeconds = TimeInterval(start)
        } else { noEvictPeriodStartSeconds = TimeInterval(0.0) }
        
        if let end = value["noEvictPeriodEndSeconds"] as? Float {
            noEvictPeriodEndSeconds = TimeInterval(end)
        } else { noEvictPeriodEndSeconds = TimeInterval(0.0) }
    }
    
    var value: [String:TimeInterval] {
        ["noEvictPeriodStartSeconds": noEvictPeriodStartSeconds, "noEvictPeriodEndSeconds": noEvictPeriodEndSeconds]
    }
    var description: String {
        "\(value)"
    }
}

extension EvictionPolicy: Equatable, Codable {
    static func == (lhs: EvictionPolicy, rhs: EvictionPolicy) -> Bool {
        lhs.noEvictPeriodStartSeconds == rhs.noEvictPeriodStartSeconds && lhs.noEvictPeriodEndSeconds == rhs.noEvictPeriodEndSeconds
    }
}

struct EvictionsMetadata: CustomStringConvertible {
    var evictionInterval: TimeInterval //seconds
    var TTLs: [String: TimeInterval]?
    var queries: [String: String]?
    var policy: EvictionPolicy?
    
    init() {
        evictionInterval = 0
    }
    
    init(interval: TimeInterval, TTLs: [String: TimeInterval]?, queries: [String:String]?, policy: EvictionPolicy?) {
        self.evictionInterval = interval
        self.TTLs = TTLs
        self.queries = queries
        self.policy = policy
    }
    
    /* N.B.
     Double/TimeInterval values can go into a dictionary but when they come back in DittoResultItems
     they are Floats, so we must transform them into the model types.
     */
    init(value map: [String:Any?]) {
        if let interval = map["evictionInterval"] as? Float {
            evictionInterval = TimeInterval(interval)
        } else {
            evictionInterval = TimeInterval(0.0)
        }
                
        if let ttls = map["TTLs"] as? [String: Float] {
            TTLs = ttls.mapValues { TimeInterval($0) }
        }
        
        queries = map["queries"] as? [String: String]
        
        if let evictPolicy = map["policy"] as? [String:Any?] {
            policy = EvictionPolicy(value: evictPolicy)
        }
    }
    
    var value: [String:Any] {
        var map: [String:Any] = ["evictionInterval": evictionInterval]
        if let ttls = TTLs { map["TTLs"] = ttls }
        if let queries = queries { map["queries"] = queries }
        if let policy = policy   { map["policy"] = policy.value }
        return map
    }
    
    var description: String {
        "\(value)"
    }
}

extension EvictionsMetadata: Equatable, Codable {
    static func == (lhs: EvictionsMetadata, rhs: EvictionsMetadata) -> Bool {
        lhs.evictionInterval == rhs.evictionInterval 
        && lhs.queries == rhs.queries
        && lhs.TTLs == rhs.TTLs
        && lhs.policy == rhs.policy
    }
}

struct AppConfig: Codable {
    var _id: [String:String]
    var id: String { _id["id"]! }
    var locationId: String { _id["locationId"]! }
    var version: Float?
    var evictions: EvictionsMetadata?
    var lastUpdated: Date?
    
    init(_id: [String:String], version: Float?, evictions: EvictionsMetadata?, lastUpdated: Date? = nil) {
        self._id = _id
        self.version = version
        self.evictions = evictions
        self.lastUpdated = lastUpdated
    }
    
    init(value map: [String:Any?]) {
        _id = map["_id"] as! [String:String]
        version = map["version"] as? Float
        if let lastUpdate = map["lastUpdated"] as? String { lastUpdated = Date.fromIsoString(lastUpdate) }
        if let evictionsMap = map["evictions"] as? [String:Any?] {
            evictions = EvictionsMetadata(value: evictionsMap)
        }
    }
    
    var value: [String:Any] {
        var map = [String:Any]()
        map["_id"] = _id
        if let version = version { map["version"] = version }
        if let lastUpdate = lastUpdated { map["lastUpdated"] = lastUpdate.isoString() }
        if let evictionsMeta = evictions { map["evictions"] = evictionsMeta.value }
        return map
    }
}

extension AppConfig: CustomStringConvertible {
        var description: String {
            return "locationId: \(locationId), "
            + "version: \(version ?? 0.0), "
            + "evictions: \(evictions?.description ?? "nil")"
            + "lastUpdated: \(lastUpdated?.isoString() ?? "nil")"
        }
}
extension AppConfig {
    func prettyPrint() -> String {
        """
        {
            "_id": {
                "id": \(id),
                "locationId": \(locationId)
            },
            "version": \(version == nil ? "undefined" : version!.stringToTwoDecimalPlaces()),
            "evictions": {
                "evictionInterval": \(evictionInterval == nil ? "undefined" : String(evictionInterval!)),
                "TTLs": \(printTTLs),
                "policy": {
                    "noEvictPeriodStartSeconds": \(policy == nil ? "undefined" : String(noEvictPeriodStartSeconds!)),
                    "noEvictPeriodEndSeconds": \(policy == nil ? "undefined" : String(noEvictPeriodEndSeconds!)),
                },
                "queries": \(printQueries),
            },
            "lastUpdated": "\(lastUpdated == nil ? "undefined" : lastUpdated!.isoString())"
        }
        """
    }

    var printQueries: String {
        guard let qs = queries else { return "undefined" }
        var str = "{\n"
        for key in qs.keys {
            str += "\t\t\"\(key)\": \"\(qs[key]!)\"\n"
        }
        str += "\t  }"
        return str
    }
    
    var printTTLs: String {
        guard let ttls = TTLs else { return "undefined" }
        var str = "{\n"
        for key in ttls.keys {
            str += "\t\t\"\(key)\": \(ttls[key]!)\n"
        }
        str += "\t  }"
        return str
    }
}

infix operator ~==
infix operator !~==
extension AppConfig {
    static func ~== (lhs: AppConfig, rhs: AppConfig) -> Bool {
        (
            lhs._id == rhs._id
            && lhs.version == rhs.version
            && lhs.evictionInterval == rhs.evictionInterval
            && lhs.TTLs == rhs.TTLs
            && lhs.noEvictPeriodStartSeconds == rhs.noEvictPeriodStartSeconds
            && lhs.noEvictPeriodEndSeconds == rhs.noEvictPeriodEndSeconds
        )
    }
    static func !~== (lhs: AppConfig, rhs: AppConfig) -> Bool {
        !(lhs ~== rhs)
    }
}

extension AppConfig: Equatable {
    static func == (lhs: AppConfig, rhs: AppConfig) -> Bool {
        lhs._id == rhs._id && lhs.version == rhs.version && lhs.evictions == rhs.evictions
    }
}

// convenience eviction attributes accessors
extension AppConfig {
    var evictionInterval: TimeInterval? {
        get { evictions?.evictionInterval }
        set {
            if evictions == nil { evictions = EvictionsMetadata() }
            var val = newValue ?? 0
            if val < 0 { val = 0 }
            evictions!.evictionInterval = val
        }
    }
    
    var policy: EvictionPolicy? {
        get { evictions?.policy }
        set {
            guard let val = newValue else {
                evictions?.policy = newValue
                return
            }
            if evictions == nil { evictions = EvictionsMetadata() }
            if evictions?.policy == nil { evictions!.policy = EvictionPolicy() }
            evictions!.policy = val
        }
    }
    
    var noEvictPeriodStartSeconds: TimeInterval? {
        get { evictions?.policy?.noEvictPeriodStartSeconds }
        set {
            guard var val = newValue else { return }
            if evictions == nil { evictions = EvictionsMetadata() }
            if evictions?.policy == nil { evictions!.policy = EvictionPolicy() }
            if val < 0 { val = 0 }
            evictions!.policy!.noEvictPeriodStartSeconds = val
        }
    }
    var noEvictPeriodEndSeconds: TimeInterval? {
        get { evictions?.policy?.noEvictPeriodEndSeconds }
        set {
            guard var val = newValue else { return }
            if evictions == nil { evictions = EvictionsMetadata() }
            if evictions?.policy == nil { evictions!.policy = EvictionPolicy() }
            if val < 0 { val = 0 }
            evictions!.policy!.noEvictPeriodEndSeconds = val
        }
    }
    
    var TTLs: [String:TimeInterval]? {
        get { evictions?.TTLs }
        set {
            if newValue == nil { evictions?.TTLs = nil }
            
            if evictions == nil { evictions = EvictionsMetadata() }
            evictions!.TTLs = newValue
        }
    }
    
    var queries: [String:String]? {
        get { evictions?.queries }
        set {
            guard let val = newValue else {
                evictions?.queries = newValue
                return
            }
            if evictions == nil { evictions = EvictionsMetadata() }
            evictions!.queries = val
        }
    }
}

extension AppConfig {
    func ttlOrDefault(collection: String) -> TimeInterval {
        TTLs?[collection] ?? Self.Defaults.evictionTTLs[ordersKey]!
    }
}

extension AppConfig {
    struct Defaults {
        static let collection = "orders"
        static let localDefaultId = "AppConfigLocalDefault"
        static let publishedDefaultId = "AppConfigPublished"
        
        /* N.B.
         - To use this default config as local-only, leave locationId unchanged. Regardless of
         the actual locationId, the default "00000" identifies the AppConfig as default local-only
         elsewhere in code.
         - "id" element is arbitrary and may be changed as desired
         */
        static let configID = ["id": localDefaultId, "locationId": Location.defaultLocation]
        
        static let version: Float = 1.0
        
        static let evictionInterval = TimeInterval(60 * 60 * 24) // 24 hours
        
        static let evictionTTLs = [ordersKey: Order.defaultOrdersTTL]
        
        static let evictionQueries = [
            ordersKey:
            """
            EVICT FROM COLLECTION `\(collection)` (saleItemIds MAP, transactionIds MAP)
            """
        ]

        static let noEvictPeriodStartSeconds = 0.0
        static let noEvictPeriodEndSeconds = 0.0
        static let evictionPolicy = EvictionPolicy(
            noEvictPeriodStartSeconds: noEvictPeriodStartSeconds,
            noEvictPeriodEndSeconds: noEvictPeriodEndSeconds
        )
        
        static let evictions = EvictionsMetadata(
            interval: evictionInterval, TTLs: evictionTTLs, queries: evictionQueries, policy: evictionPolicy
        )

        static var defaultConfig: AppConfig {
            AppConfig(_id: configID, version: version, evictions: evictions)
        }

        static func insertQuery(config: AppConfig) -> DittoQuery {
            (
                string: """
                INSERT INTO COLLECTION configuration (evictions MAP(TTLs MAP, queries MAP, policy MAP))
                DOCUMENTS (:config)
                ON ID CONFLICT DO UPDATE
                """,
                args: [ "config": config.value ]
            )
        }
        
        static func registerQuery(locId: String) -> DittoQuery {
            (
                string: """
                SELECT * FROM COLLECTION configuration (evictions MAP(TTLs MAP, queries MAP, policy MAP))
                WHERE _id.locationId = :locationId
                ORDER BY version DESC
                """,
                args: [
                    "locationId": locId,
                ]
            )
        }
    }
}

/* Schema update with TTLs
{
  "_id": {
    "id": "AppConfigPublished",
    "locationId": "Ditto-EvictionTest"
  },
  "evictions": {
    "TTLs": {
      "orders": 7200
    },
    "evictionInterval": 86400,
    "policy": {
      "noEvictPeriodEndSeconds": 0,
      "noEvictPeriodStartSeconds": 0
    },
    "queries": {
      "orders": "EVICT FROM COLLECTION `orders` (saleItemIds MAP, transactionIds MAP) "
    }
  },
  "lastUpdated": "2024-05-26T08:01:01.483Z",
  "version": 1
}
*/
