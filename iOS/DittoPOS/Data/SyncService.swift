///
//  SubscriptionsManager.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/19/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation
import OSLog


final class SyncService {
    private let sync: DittoSync

    private(set) var locationsSubscription: DittoSyncSubscription?
    private(set) var ordersSubscription: DittoSyncSubscription?
    private(set) var configSubscription: DittoSyncSubscription?

    init(_ sync: DittoSync) {
        self.sync = sync
    }

    func registerInitialSubscriptions() {
        do {
            Logger.sync.info("Sync.\(#function,privacy:.public): Registering initial location subscription")
            try locationsSubscription = sync.registerSubscription(
                query: Location.selectAllQuery.string
            )
            
            Logger.sync.info("Sync.\(#function,privacy:.public): Registering initial order subscription")
            try ordersSubscription = sync.registerSubscription(
                query: Order.defaultLocationSyncQuery.string,
                arguments: Order.defaultLocationSyncQuery.args
            )

            /* orig
            Logger.sync.info("Registering appConfig subscription")
            try configSubscription = sync.registerSubscription(
                query: "SELECT * FROM COLLECTION configuration (evictions MAP(queries MAP, policy MAP))"
            )
             */            
        } catch {
            Logger.sync.error(
                "Sync.\(#function,privacy:.public): Error when registering initial order subscription: \(error.localizedDescription,privacy:.public)"
            )
            assertionFailure("SyncService: ERROR with \(#function): " + error.localizedDescription)
        }
    }
    
    func registerAppConfigSubscription(locId: String) {
        Logger.sync.info("Sync.\(#function,privacy:.public): Registering appConfig subscription for locId: \(locId,privacy:.public)")
        configSubscription?.cancel()
        configSubscription = nil
        
        let query = AppConfig.Defaults.registerQuery(locId: locId)
        do {
            try configSubscription = sync.registerSubscription(
                query: query.string,
                arguments: query.args
            )
            /* orig
            try configSubscription = sync.registerSubscription(
                query: AppConfig.Defaults.registerQueryString
            )
             */
        } catch {
            Logger.sync.error(
                "Sync.\(#function,privacy:.public): Error when registering initial order subscription: \(error.localizedDescription,privacy:.public)"
            )
            assertionFailure("SyncService: ERROR with \(#function): " + error.localizedDescription)
        }
    }
    
    func unregisterAppConfigSubscription() {
        Logger.sync.info("Sync.\(#function,privacy:.public): Un-register appConfig subscription")
        configSubscription?.cancel()
        configSubscription = nil
    }

    @discardableResult
    func registerOrdersSinceTTLSubscription(locId: String, ttl: TimeInterval) -> DittoQuery {
        
        let query = Order.ordersQuerySinceTTL(locId: locId, ttl: ttl)
        //        Logger.sync.info("Sync.\(#function,privacy:.public): Registering orders subscription since TTL with ttl: \(ttl,privacy:.public)\nquery: \(query.string)")
        if let logQueryString = fullOrdersTTLQueryString() {
            Logger.eviction.warning("SyncService.\(#function,privacy:.public): called: \(Date.now.standardFormat(),privacy:.public)\nfullQueryString: \(logQueryString,privacy:.public)\nTTL: \(ttl,privacy:.public)\n ttl in query string should be \(DateFormatter.isoTimeFromNowString(-ttl),privacy:.public)\nttl in localTime: \(Date.now.addingTimeInterval(-ttl).standardFormat(),privacy:.public)")
        }

        do {
            ordersSubscription = try sync.registerSubscription(
                query: query.string,
                arguments: query.args
            )
        } catch {
            Logger.sync.error(
                "Sync.\(#function,privacy:.public): Error when registering orders since TTL subscription: \(error.localizedDescription,privacy:.public)"
            )
            assertionFailure("SyncService: ERROR with \(#function): " + error.localizedDescription)
        }
        return query
    }

    func cancelOrdersSubscription() {
        Logger.sync.info("Sync.\(#function,privacy:.public): Cancelling orders subscription")
        ordersSubscription?.cancel()
        ordersSubscription = nil
    }
}

extension SyncService {

    //for ttl subscription registration logging (above)
    func fullOrdersTTLQueryString() -> String? {
        let key = ordersKey
        let config = DittoService.shared.appConfig
        let stub = Order.defaultOrdersSubQueryStub()
        
        guard let locId = DittoService.shared.currentLocationId else {
            Logger.eviction.warning("Sync.\(#function,privacy:.public): DittoService.currentLocationId is NIL --> Return")
            return nil
        }
        guard let ttl = config.TTLs?[key] as? TimeInterval else {
            Logger.eviction.error("Sync.\(#function,privacy:.public): config.TTLs value for key: \(key,privacy:.public) NOT FOUND")
            return nil
        }
        
        let verb = stub.uppercased().contains(" AND ") ? " AND" : " WHERE"
        
        var clause = "\(verb) _id.locationId = '\(locId)'"
        clause += " AND createdOn >= '\(Date.now.addingTimeInterval(-ttl).isoString())'"
        
        let queryString = stub + """
        
        \(clause)
        """
        
        return queryString
    }
}

