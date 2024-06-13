///
//  EvictionService.swift
//  BGTaskTest2
//
//  Created by Eric Turner on 4/18/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import BackgroundTasks
import Combine
import DittoSwift
import NotificationCenter
import OSLog
import SwiftUI

class EvictionService {
    static var shared = EvictionService()
    let evictionBgTaskID = "live.ditto.eviction.bgTaskID" //must match in Info.plist

    private var dittoService: DittoService
    private let dittoStore: DittoStore
    private let logger = EvictionLogger()

    private var configCancellable = AnyCancellable({})
    private var notificationCancellable = AnyCancellable({})

    private var appConfig: AppConfig?
    private var evictionInterval: Int = Settings.defaultEvictionInterval
    
    init() {
        dittoService = DittoService.shared
        dittoStore = dittoService.ditto.store
        updateAppConfigPublisher()
        
        notificationCancellable = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink {[weak self] _ in
                Logger.eviction.debug("didBecomeActiveNotification fired; force appConfig refresh: \(Date.now,privacy:.public)")
                // Force refresh the appConfig every time application becomes active
                self?.updateAppConfigPublisher()
            }
    }
    
    func updateAppConfigPublisher() {
        configCancellable = dittoService.$appConfig
            .receive(on: DispatchQueue.main)
            .sink {[weak self] config in
                guard let self = self else { return }
                if let conf = config {
                    Logger.eviction.info("updateAppConfigPublisher(): appConfig v\(conf.version!) in")
                } else {
                    Logger.eviction.debug("updateAppConfigPublisher(): NIL appConfig in")
                }
                
                // Only reset the appConfig var if different than what we already have
                if appConfig != config {
                    Logger.eviction.debug("updateAppConfigPublisher(): SET UPDATED appConfig")
                    appConfig = config

                    if let interval = config?.evictions?.evictionInterval, interval != evictionInterval {
                        Logger.eviction.debug("updateAppConfigPublisher(): SET evictionInterval: \(interval,privacy:.public)")
                        evictionInterval = interval
                        
                        // Call to reschedule background eviction task every time appConfig updates
                        Task {
                            await self.scheduleBackgroundEvictionIfNeeded()
                        }
                    }
                }
                /* orig
                appConfig = config
                if let interval = config?.evictions?.evictionInterval, interval != evictionInterval {
                    Logger.eviction.debug("updateAppConfigPublisher(): SET evictionInterval: \(interval,privacy:.public)")
                    evictionInterval = interval
                }
                 */
            }
    }
    
    //MARK: Eviction Process Background/Foreground
    
    func runEvictionQueries(task: BGProcessingTask? = nil, testing: Bool = false) {
        Logger.eviction.debug("runEvictionQueries: in -> iso: \(Date.now.isoString(),privacy:.public)")
        
        // do we have an appConfig?
        guard let config = appConfig else {
            Logger.eviction.error("runEvictionQueries(): No appConfig. Return")
            handleTaskCompletion(task, success: false)
            return
        }
        // do we have a current location?
        guard let currentLocId = dittoService.currentLocationId else {
            Logger.eviction.error("runEvictionQueries():  dittoService.currentLocationId for eviction queries. Return")
            handleTaskCompletion(task, success: false)
            return
        }
        // do appConfig location and current location match?
        guard currentLocId == config.locationId else {
            Logger.eviction.error("runEvictionQueries(): currentLocationId does not match config locId. Return")
            handleTaskCompletion(task, success: false)
            return
        }
        // do we have appConfig queries structure?
        guard let evictionQueries = config.evictions?.queries else {
            Logger.eviction.error("runEvictionQueries(): queries not found in appConfig. Return")
            handleTaskCompletion(task, success: false)
            return
        }
        // is the queries structure empty of queries?
        guard evictionQueries.count > 0 else {
            Logger.eviction.debug("runEvictionQueries(): appConfig queries count: \(evictionQueries.count,privacy:.public). Return")
            handleTaskCompletion(task, success: true)
            return
        }
        // are we in the "no evict" period window?
        guard currentLocalTimeIsWithinNoEvictPeriod() == false else {
            Logger.eviction.debug("runEvictionQueries(): Current local time is within NO EVICT period window. Return")
            handleTaskCompletion(task, success: false)
            return
        }
        
        // cancel subscptions before evicting!
        dittoService.syncService.cancelOrdersSubscription()
                
        Task {
            let evictionEpoch = Date.now
            var evictionQueryError: Error? = nil
            
            for (key, query) in evictionQueries {
                
                do {
                    Logger.eviction.debug("Eviction BgTask: execute query: \(query,privacy:.public)")

                    // eviction query execution
                    let result = try await dittoStore.execute(query: query)
                    
                    let mutDocIds = result.mutatedDocumentIDs()
                    var logBundle = EvictionLogBundle(
                        query: query,
                        queryKey: key,
                        queryTimestamp: Date.now.isoString(),
                        docIDs: mutDocIds,
                        epoch: evictionEpoch.isoString()
                    )
                    
                    // Optionally, add arbitrary key/vals to bundle details map
                    // Example:
                    logBundle.details = [
                        "deviceName": "\(dittoService.ditto.siteID)",
                        "sdkVersion": "\(dittoService.ditto.sdkVersion)"
                    ]
                    
                    logger.addLog(bundle: logBundle, foreground: task == nil)
                    
                    Logger.eviction.debug("\(key,privacy:.public) eviction BgTask: execute query mutatedDocumentIDs.count: \(mutDocIds.count,privacy:.public)\n Note: these may replicate back immediately while testing eviction.")
                } catch {
                    Logger.eviction.error("\(#function,privacy:.public): ERROR for query \(query,privacy:.public):\n \(error.localizedDescription,privacy:.public)")
                    evictionQueryError = error
                }
            }

            Settings.lastEvictionDate = evictionEpoch
            
            if testing {
                dittoService.syncService.testRegisterOrdersSinceTTLSubscription(ttl: Date.now)
            } else {
                dittoService.syncService.registerOrdersSinceTTLSubscription(locId: currentLocId)
            }
                        
            if let task = task {
                Logger.eviction.debug("\(#function,privacy:.public): setTaskCompleted(success: true) at \(Date.now,privacy:.public)")
                task.setTaskCompleted(success: evictionQueryError == nil)
                
                // schedule for the next cycle
                await scheduleBackgroundEvictionIfNeeded()
                
                task.expirationHandler = {
                    Logger.eviction.debug("\(#function,privacy:.public): task.expirationHandler: setTaskCompleted(success: true) at \(Date.now,privacy:.public)")
                    task.setTaskCompleted(success: true)
                }
            }
        }
    }
    
    func handleTaskCompletion(_ task: BGTask?, success: Bool) {
        if let task = task {
            Task {
                await scheduleBackgroundEvictionIfNeeded()
                task.setTaskCompleted(success: success)
                Logger.eviction.debug("SET setTaskCompleted(success: \(success,privacy:.public)")
            }
        }
    }
}

//MARK: Foreground
extension EvictionService {

    func handleForegroundEviction() {
        guard evictionPermissibleNow() else {
            Logger.eviction.debug("SKIP eviction - not permissible now: \(Date.now,privacy:.public)")
            return
        }
        
        Logger.eviction.debug("RUN foreground eviction now: \(Date.now,privacy:.public)")
        runEvictionQueries()
    }
    
    func evictionPermissibleNow() -> Bool {
        currentLocalTimeIsWithinNoEvictPeriod() == false
        && Date.now >= nextEvictionIntervalEpoch()
        && Date.now >= earliestDateByPolicy()//earliestPermissibleEvictionPolicyDate()
    }
}

//MARK: Register Background Task
extension EvictionService {
    
    func registerEvictionBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: evictionBgTaskID,
            using: nil
        ) { task in
            self.handleBackgroundEviction(task: task as! BGProcessingTask)
        }
        Logger.eviction.debug("registerEvictionBackgroundTask() called at \(Date(), privacy: .public)")
    }
}

//MARK: Schedule Background Task
extension EvictionService {
    
    func scheduleBackgroundEvictionIfNeeded() async {
        // short-circuit here if we don't have appConfig
        guard let _ = appConfig else {
            Logger.eviction.error("scheduleBackgroundEviction(): NIL appConfig. Return")
            return
        }

        let proposedEarliestBeginDate = nextEvictionIntervalEpoch()
        
        // Check: do we have a task already scheduled? If so, is it already scheduled for the
        // same time as we would schedule now, i.e. lastEvictionDate + evictionTimeInterval?
        // This function is called when the AppConfig updates, and everytime the app becomes active,
        // so we're checking to see if we need to reschedule an already-scheduled task, perhaps
        // from an update to an appConfig params.
        let requests = await BGTaskScheduler.shared.pendingTaskRequests()
        if let scheduledEarliestBeginDate = requests.last?.earliestBeginDate {
            
            // If the scheduled date is not the same as last eviction run + interval, cancel
            if scheduledEarliestBeginDate != proposedEarliestBeginDate {
                Logger.eviction.debug("registerEvictionBackgroundTask(): scheduledEarliestBeginDate != proposedEarliestBeginDate. Cancel all BackgroundTasks")
                BGTaskScheduler.shared.cancelAllTaskRequests()
            }
            // Otherwise, we're already scheduled for the correct time, so we can skip
            else {
                let scheduledDate = scheduledEarliestBeginDate.isoString()
                Logger.eviction.info(
                    "scheduleBackgroundEviction: pendingTaskRequests.count: \(requests.count,privacy:.public). Skipping...\nLatest request.earliestBeginDate: \(scheduledDate,privacy:.public)"
                )
                return
            }
        }
        
        let request = BGProcessingTaskRequest(identifier: evictionBgTaskID)
        request.earliestBeginDate = proposedEarliestBeginDate
                
        do {
            try BGTaskScheduler.shared.submit(request)
            /* DEBUG:
             1. set breakpoint on next line.
             2. when triggered, in debugger console paste in:
                e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"live.ditto.eviction.bgTaskID"]
             3. continue execution
             */
            Logger.eviction.debug(
                "SUBMIT EVICTION BGTask scheduled earliest: \(request.earliestBeginDate!,privacy:.public)"
            )
        } catch {
            Logger.eviction.error(
                "Could not schedule background eviction for \(request.earliestBeginDate!,privacy:.public)\n: \(error,privacy:.public)"
            )
        }
    }
        
    func handleBackgroundEviction(task: BGProcessingTask) {
        runEvictionQueries(task: task)
    }
}

// Utilities
extension EvictionService {
    
    func nextEvictionIntervalEpoch() -> Date {
        // If we haven't run an eviction yet (app 1st launch)
        // set the 1st epoch to earliest permissable
        guard let _ = Settings.lastEvictionDate else {
            let earliestPermissable = earliestDateByPolicy()//earliestPermissibleEvictionPolicyDate()
            Settings.lastEvictionDate = earliestPermissable
            return earliestPermissable
        }
        let lastEpoch = Settings.lastEvictionDate!
        return lastEpoch.addingTimeInterval(TimeInterval(evictionInterval))
    }
    
    // Evaluate eviction policy start/end period times relative to now,
    // irrespective of current or previous epoch; return soonest permissable eviction date
//    func earliestPermissibleEvictionPolicy() -> Date {
    func earliestDateByPolicy() -> Date {
        guard let config = appConfig, let policy = config.evictions?.policy else {
            return Date.now
        }
        
        let now = Calendar.localTimeNowSeconds
        let periodStart = policy.noEvictStartSeconds // 28800 8:00am
        let periodEnd = policy.noEvictEndSeconds     // 72000 8:00pm

        // Example: Start 28800 - End 72000
        if periodStart < periodEnd {
            if now >= periodStart && now <= periodEnd {
                return Date.now.addingTimeInterval(TimeInterval(periodEnd - now))
            }
            return Date.now
        }
        // Example: Start 72000 - End 28800, spanning midnight
        else if now >= periodStart {
            let secondsToMidnight = 86400 - now
            return Date.now.addingTimeInterval(TimeInterval(secondsToMidnight + periodEnd))
        } else if now <= periodEnd {
            return Date.now.addingTimeInterval(TimeInterval(periodEnd - now))
        }
    }
    
    // Return true if eviction should not be performed now; false if outside "no evict window" period
    func currentLocalTimeIsWithinNoEvictPeriod() -> Bool {
        guard let policy = appConfig?.evictions?.policy else {
            Logger.eviction.info("\(#function,privacy:.public): No eviction policy found. Returning true.")
            return true
        }
        
        let now = Calendar.localTimeNowSeconds
        let periodStart = policy.noEvictStartSeconds
        let periodEnd = policy.noEvictEndSeconds
        
        if periodStart < periodEnd {
            // start and end are within same day
            return now >= periodStart && now <= periodEnd
        } else {
            // start time spans over midnight to next day end time
            return now >= periodStart || now <= periodEnd
        }
    }
}

extension Calendar {
    static var localTimeNowSeconds: Int {
        let comps = Calendar.current.dateComponents(in: TimeZone.current, from: Date.now)
        return (comps.hour! * 3600 + comps.minute! * 60 + comps.second!)
    }
}


// This test extension stays in this file for use of the private dittoStore instance
extension EvictionService {
    
    func testInsertAppConfig(evictFrom: Date = Date.now) {
        Logger.eviction.error("testInsertAppConfig: insert appConfig - evict older than \(evictFrom.isoString(),privacy:.public)")
        
        let insertQuery = appConfigInsertQuery
        
        let evictQuery = testEvictQuery(from: evictFrom)
        let queries = ["orders": "\(evictQuery)"]
        
        let policy = EvictionPolicy(
            noEvictStartSeconds: 60 * 60 * 8, // 8am,
            noEvictEndSeconds: 60 * 60 * 20   // 8pm
        )
        
        let locId = dittoService.currentLocationId!
        let version = Float(1.5)
        
        let evictions = EvictionsMetadata (
            interval: 360,
            queries: queries,
            policy: policy
        )
        var appConfig = AppConfig(
            locId: locId,
            version: version,
            evictions: evictions
        ).value
        appConfig["_id"] = "appConfig2"
        let config = appConfig
        
        
        Task {
            do {
                try await dittoStore.execute(query: insertQuery, arguments: ["config": config])
            } catch {
                Logger.eviction.error("testInsertAppConfig: \(error.localizedDescription,privacy:.public)")
            }
        }
    }
    
    private func testEvictQuery(from: Date) -> String {
        var evictQuery = """
        EVICT FROM COLLECTION `orders` (saleItemIds MAP, transactionIds MAP)
        WHERE createdOn <= '\(from.isoString())'
        """
        // Evict all specified in query EXCEPT for current order, to avoid UI problems
        // this is fragile and of questionable real life logic, but it's only for real-time eviction testing (right?)
        if let curOrder = POS_VM.shared.currentOrder {
            evictQuery += " AND _id.id != '\(curOrder.id)'"
        }
        return evictQuery
    }
    
    private var appConfigInsertQuery: String {
        """
        INSERT INTO COLLECTION configuration (evictions MAP(queries MAP, policy MAP))
        DOCUMENTS (:config)
        ON ID CONFLICT DO UPDATE
        """
    }
}

/*
 AppConfig schema
 {
   "_id": "appConfig2",
   "evictions": {
     "evictionInterval": 360,
     "policy": {
       "noEvictPeriodEnd": 72000,
       "noEvictPeriodStart": 28800
     },
     "queries": {
       "orders": "EVICT FROM COLLECTION orders (saleItemIds MAP, transactionIds MAP)\nWHERE createdOn <= '2024-05-03T18:32:40.184Z' AND _id.id != '12A13E16-70D4-407D-8755-B5BC36404DF6'"
     }
   },
   "locationId": "DittoCX-Eviction",
   "version": 1.5
 }
 */
