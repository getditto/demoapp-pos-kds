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

    private(set) var appConfig = DittoService.shared.appConfig
    private var nextScheduledBgTask: Date?
    
    private var configCancellable = AnyCancellable({})
    private var notificationCancellable = AnyCancellable({})
    
    
    init() {
        dittoService = DittoService.shared
        dittoStore = dittoService.ditto.store
        updateAppConfigPublisher()
        
        notificationCancellable = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink {[weak self] _ in
                Logger.eviction.warning("ES.didBecomeActiveNotification fired; force appConfigPublisher refresh: \(Date.now.standardFormat(),privacy:.public)")
                
                // Force refresh the appConfig publisher every time application becomes active
                self?.updateAppConfigPublisher()
            }
    }
    
    func updateAppConfigPublisher() {
        configCancellable = dittoService.$appConfig
            .receive(on: DispatchQueue.main)
            .sink {[weak self] config in
                guard let self = self else { return }
                
                Logger.eviction.info("ES.updateAppConfigPublisher(): config.id: \(config.id) v\(config.version == nil ? "NIL" : String(config.version!)) in")
                
                // does this even make sense? this publisher only fires with changes, right?
                if appConfig != config {
                    Logger.eviction.info("ES.updateAppConfigPublisher(): CHANGED --> SET appConfig")
                }
                
                /* Check to see if orders TTL config value has changed.
                 N.B. this check is specific to orders and doesn't consider
                 TTLs for other collections.
                 */
                if let newTTL = config.TTLs?[ordersKey],
                    let oldTTL = appConfig.TTLs?[ordersKey],
                   newTTL != oldTTL {
                    dittoService.resetOrdersSubscription(ttl: newTTL)
                }

                appConfig = config

                Task {
                    await self.scheduleBackgroundEvictionIfNeeded()
                }
            }
    }
    
    var evictionInterval: TimeInterval {
        appConfig.evictions?.evictionInterval ?? 0.0
    }
    
    var policyPeriodStart: TimeInterval {
        TimeInterval(appConfig.policy?.noEvictPeriodStartSeconds ?? 0.0)
    }
    
    var policyPeriodEnd: TimeInterval {
        TimeInterval(appConfig.policy?.noEvictPeriodEndSeconds ?? 0.0)
    }
 
    //MARK: Eviction Process Background/Foreground
    
    @discardableResult
    func runEvictionQueries(task: BGProcessingTask? = nil, mode: EvictionMode, config: AppConfig? = nil) async -> String {
        
        Logger.eviction.warning("ES.\(#function,privacy:.public): Called at: \(Date.now.standardFormat(),privacy:.public) with mode: \(mode.rawValue,privacy:.public)")
        
        var returnMsg = ""

        // do we have a current location?
        guard let currentLocId = dittoService.currentLocationId else {
            Logger.eviction.error("ES.\(#function,privacy:.public): Aborted: NIL dittoService.currentLocationId")
            
            await handleTaskCompletion(task, success: false)
            
            returnMsg += "Eviction Aborted: NIL dittoService.currentLocationId"
            logger.addAbortLog(msg: returnMsg, mode: mode, details: loggingDetailsStub())
            
            return returnMsg
        }
        
        // does appConfig.locationId and current.locationId match OR are we using local-only config?
        guard currentLocId == appConfig.locationId || appConfig.locationId == AppConfig.Defaults.defaultConfig.locationId else {
            Logger.eviction.error("ES.\(#function,privacy:.public): Aborted: appConfig.locationId != dittoService.currentLocationId")
            
            await handleTaskCompletion(task, success: false)
            
            returnMsg += "Eviction Aborted: appConfig.locationId != dittoService.currentLocationId"
            logger.addAbortLog(msg: returnMsg, mode: mode, details: loggingDetailsStub())
            return returnMsg
        }
        
        // do we have either test queries or AppConfig queries map?
        guard let evictionQueries = config?.queries ?? appConfig.queries  else {
            if mode == .test {
                Logger.eviction.error("ES.\(#function,privacy:.public): TEST queries NOT FOUND --> Abort")
                returnMsg += "TEST queries NOT FOUND, ABORT"
            } else {
                returnMsg += "appConfig.queries NOT FOUND, ABORT"
                Logger.eviction.error("ES.\(#function,privacy:.public): appConfig.queries NOT FOUND --> Abort")
            }

            await handleTaskCompletion(task, success: false)

            logger.addAbortLog(msg: returnMsg, mode: mode, details: loggingDetailsStub())
            return returnMsg
        }

        // is the queries dictionary empty of queries?
        guard evictionQueries.count > 0 else {
            Logger.eviction.warning("ES.\(#function,privacy:.public): ZERO appConfig queries found --> Abort")
            
            await handleTaskCompletion(task, success: true)
            
            returnMsg += "Eviction Aborted: Empty appConfig queries"
            logger.addAbortLog(msg: returnMsg, mode: mode, details: loggingDetailsStub())
            return returnMsg
        }
        
        if currentlyWithinNoEvictPeriod() && mode.isForced == false {
            Logger.eviction.warning("ES.\(#function,privacy:.public): ABORT: currently within no-evict policy window")
            
            await handleTaskCompletion(task, success: false)
            
            returnMsg += "Eviction Aborted: currently within no-evict policy window"
            logger.addAbortLog(msg: returnMsg, mode: mode, details: loggingDetailsStub())
            return returnMsg
        }
        
        if mode.isTest == false {
            // cancel subscriptions before evicting!
            dittoService.syncService.cancelOrdersSubscription()
        }
        
        let evictionEpoch = Date.now
        var evictionQueryError: Error? = nil
        
        for (collection, _ /* queryStub */) in evictionQueries {
            
            guard let query = fullEvictionQueryString(for: collection, config: config) else {
                Logger.eviction.error("ES.\(#function,privacy:.public): TTL value for key: \(collection,privacy:.public) NOT FOUND")
                continue
            }
            
            do {
                Logger.eviction.warning("ES.\(#function,privacy:.public): Eviction will execute query: \(query,privacy:.public)")

                // eviction query execution
                let result = try await dittoStore.execute(query: query)

                if mode == .forced { returnMsg += "Eviction FORCED by manual override" }
                if mode == .test { returnMsg += "TEST Eviction initiated by user" }
                
                let mutDocIds = result.mutatedDocumentIDs()
                var logBundle = EvictionLogBundle(
                    query: query,
                    queryKey: collection,
                    queryTimestamp: Date.now.isoString(), //Date.now.standardFormat(),//<-- doesn't sort correctly, revert to iso
                    opMode: mode,
                    docIDs: mutDocIds,
                    epoch: evictionEpoch.isoString()
                )
                
                // Optionally, add arbitrary key/vals to bundle details dictionary
                logBundle.details = loggingDetailsStub()
                
                returnMsg += "\n\nEviction success:"
                returnMsg += "\n(\(mutDocIds.count)) documents evicted"
                returnMsg += "\nNote: these may replicate back immediately if testing or forcing eviction."
                
                logger.addLog(bundle: logBundle)
                 
                Logger.eviction.warning(
                    "ES.\(#function,privacy:.public): execute \(logBundle.opMode.rawValue,privacy:.public) query: \(query,privacy:.public) on \"\(collection,privacy:.public)\" at: \(Date.now.standardFormat(),privacy:.public)\n mutatedDocumentIDs.count: \(mutDocIds.count,privacy:.public)\n Note: these may replicate back immediately while testing eviction."
                )
            } catch {
                Logger.eviction.error("ES.\(#function,privacy:.public): ERROR for query \(query,privacy:.public):\n \(error.localizedDescription,privacy:.public)")
                
                evictionQueryError = error
                returnMsg += "\nEviction FAIL: \(error.localizedDescription)"
            }
        }

        if mode.isTest == false {
            Settings.lastEvictionDate = evictionEpoch
            let ttl = appConfig.TTLs?[ordersKey] ?? AppConfig.Defaults.evictionTTLs[ordersKey]!
            dittoService.syncService.registerOrdersSinceTTLSubscription(locId: currentLocId, ttl: ttl)
        }
         
        // only for background task runs
        if let task = task {
            Logger.eviction.warning("ES.\(#function,privacy:.public): setTaskCompleted(success: true) at \(Date.now.standardFormat(),privacy:.public)")
            
            task.setTaskCompleted(success: evictionQueryError == nil)
            
            // schedule for the next cycle
            await scheduleBackgroundEvictionIfNeeded()
            
            task.expirationHandler = {
                Logger.eviction.warning("ES.\(#function,privacy:.public): task.expirationHandler: setTaskCompleted(success: true) at \(Date.now.standardFormat(),privacy:.public)")
                task.setTaskCompleted(success: true)
            }
        }
        
        return returnMsg
    }
    
    func loggingDetailsStub() -> [String:String] {
         [
            "deviceName": "\(dittoService.ditto.siteID)",
            "sdkVersion": "\(dittoService.ditto.sdkVersion)"
        ]
    }
    
    func handleTaskCompletion(_ task: BGTask?, success: Bool) async {
        if let task = task {
            await scheduleBackgroundEvictionIfNeeded()
            task.setTaskCompleted(success: success)
            Logger.eviction.warning("ES.\(#function,privacy:.public): SET setTaskCompleted(success: \(success,privacy:.public)")
        }
    }
    
    // Matches a key/collectionName TTLs map with key from queries map for ttl value
    func fullEvictionQueryString(for key: String, config: AppConfig? = nil) -> String? {
        let config = config ?? appConfig
        
        guard let stub = config.queries?[key] as? String else {
            Logger.eviction.error("ES.\(#function,privacy:.public): config.queries value for key: \(key,privacy:.public) NOT FOUND")
            return nil
        }
        guard let ttl = config.TTLs?[key] as? TimeInterval else {
            Logger.eviction.error("ES.\(#function,privacy:.public): config.TTLs value for key: \(key,privacy:.public) NOT FOUND")
            return nil
        }
        
        let verb = stub.uppercased().contains(" AND ") ? " AND" : " WHERE"
        
        var clause = "\(verb) _id.locationId = '\(dittoService.currentLocationId!)'"
        clause += " AND createdOn < '\(Date.now.addingTimeInterval(-ttl).isoString())'"

        let queryString = stub + """
        
        \(clause)
        """
        
        return queryString
    }
}

//MARK: Foreground
extension EvictionService {

    func handleForegroundEviction() {
        guard foregroundEvictionNeededNow() else {
            Logger.eviction.warning("ES.\(#function,privacy:.public): SKIP eviction - not permissible now: \(Date.now.standardFormat(),privacy:.public)")
            return
        }
        
        Task {
            Logger.eviction.warning("ES.\(#function,privacy:.public): RUN foreground eviction now: \(Date.now.standardFormat(),privacy:.public)")
            let msg = await runEvictionQueries(mode: .foreground)
            Logger.eviction.warning("ES.\(#function,privacy:.public): Foreground eviction completed: \(msg,privacy:.public)")
        }
    }
    
    func foregroundEvictionNeededNow() -> Bool {
        evictionIsCurrentlyDue() && evictionIsPermissibleNow()
    }
    
    func evictionIsPermissibleNow() -> Bool {
        currentlyWithinNoEvictPeriod() == false
        && evictionIsCurrentlyDue()
    }
    
    func evictionIsCurrentlyDue() -> Bool {
        Date.now >= nextEvictionEpoch()
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
        Logger.eviction.info("ES.\(#function,privacy:.public) called at \(Date.now.standardFormat(), privacy:.public)")
    }
}

//MARK: Schedule Background Task
extension EvictionService {
    
    func scheduleBackgroundEvictionIfNeeded() async {
        let requests = await BGTaskScheduler.shared.pendingTaskRequests()
        
        // if no appConfig.evictions, e.g. undefined or per updated config, cancel
        // any scheduled eviction background tasks
        guard let _ = appConfig.evictions else {
            Logger.eviction.warning(
                "ES.\(#function,privacy:.public) - NIL appConfig.evictions: CANCEL pendingTaskRequests: count: \(requests.count,privacy:.public) --> Return"
            )
            BGTaskScheduler.shared.cancelAllTaskRequests()
            return
        }

        var proposedDate = nextEvictionEpoch()
        Logger.eviction.warning(
            "ES.\(#function,privacy:.public) proposedDate from nextEvictionEpoch(): \(proposedDate.standardFormat(),privacy:.public)"
        )

        if dateIsWithinNoEvictPeriod(proposedDate) {
            proposedDate = nextPolicyPeriodEndAfterDate(Date.now)
            Logger.eviction.warning(
                "ES.\(#function,privacy:.public) proposedDate isWithinNoEvictPeriod, update to: \(proposedDate.standardFormat(),privacy:.public)"
            )
        }
        
        // Check: do we have a task already scheduled? If so, is it already scheduled for the
        // same time as we would schedule now, i.e. lastEvictionDate + evictionTimeInterval?
        // This function is called when the AppConfig updates, and everytime the app becomes active,
        // so we're checking to see if we need to reschedule an already-scheduled task, perhaps
        // from an update to appConfig.eviction params.
        if let scheduledDate = requests.last?.earliestBeginDate {
            
            // If the scheduled date is not the same as last eviction run + interval, cancel
            if scheduledDate != proposedDate {
                Logger.eviction.warning("ES.\(#function,privacy:.public): scheduledEarliestBeginDate (\(scheduledDate.standardFormat(),privacy:.public)) != proposedEarliestBeginDate (\(proposedDate.standardFormat(),privacy:.public). Cancel all BackgroundTasks")
                
                BGTaskScheduler.shared.cancelAllTaskRequests()
            }
            // Otherwise, we're already scheduled for the correct time, so we can skip
            else {
                Logger.eviction.warning(
                    "ES.\(#function,privacy:.public): pendingTaskRequests.count: \(requests.count,privacy:.public). Skipping...\nCurrently scheduled earliestBeginDate: \(scheduledDate.standardFormat(),privacy:.public)"
                )
                return
            }
        }
        
        let request = BGProcessingTaskRequest(identifier: evictionBgTaskID)
        request.earliestBeginDate = proposedDate
        Logger.eviction.warning("ES.\(#function,privacy:.public): scheduledEarliestBeginDate: \(proposedDate.standardFormat(),privacy:.public)")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            /* DEBUG:
             1. set breakpoint on next line.
             2. when triggered, in debugger console paste in:
                e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"live.ditto.eviction.bgTaskID"]
             3. continue execution
             */
            Logger.eviction.warning(
                "ES.\(#function,privacy:.public): SUBMIT EVICTION BGTask scheduled for earliest: \(request.earliestBeginDate!.standardFormat(),privacy:.public)"
            )
            
            await MainActor.run { nextScheduledBgTask = request.earliestBeginDate }
        } catch {
            Logger.eviction.error(
                "ES.\(#function,privacy:.public): ERROR: Could not schedule background eviction for earliest: \(request.earliestBeginDate!.standardFormat(),privacy:.public)\n: \(error,privacy:.public)"
            )
        }
    }
        
    func handleBackgroundEviction(task: BGProcessingTask) {
        Task { await runEvictionQueries(task: task, mode: .background) }
    }
}

// Utilities
extension EvictionService {
    
    func nextEvictionEpoch() -> Date {
//        let nextEpoch = lastEvictionEpoch().addingTimeInterval(evictionInterval)
//        let lastEpoch = lastEvictionEpoch() // ensure side-effect to set 1st epoch (1st launch)
        var nextEpoch = Date.now.addingTimeInterval(evictionInterval)
        
        if let lastEpoch = lastEvictionEpoch() {
            nextEpoch = lastEpoch.addingTimeInterval(evictionInterval)
            
            //TESTING: how does this relate to next scheduled bgTask?
            if let nextBgTask = nextScheduledBgTask, nextEpoch != nextBgTask {
                Logger.eviction.warning("ES.\(#function,privacy:.public): WARNING: nextEpoch: \(nextEpoch.standardFormat(),privacy:.public) != next scheduled BgTask: \(nextBgTask.standardFormat(),privacy:.public)")
            }            
        }
        
//        Logger.eviction.warning("ES.\(#function,privacy:.public): Return nextEpoch: \(nextEpoch.standardFormat(),privacy:.public)")
        return nextEpoch
    }
    
    func lastEvictionEpoch() -> Date? {
        /*
        // If we haven't run an eviction yet (app 1st launch)
        // set the 1st epoch to earliest permissable
        guard let _ = Settings.lastEvictionDate else {
            let earliestPermissable = earliestPermittedEvictionDate()
            Settings.lastEvictionDate = earliestPermissable
            
            Logger.eviction.warning("ES.\(#function,privacy:.public): lastEvictionDate NOT FOUND (1st launch?)")
            Logger.eviction.warning("ES.\(#function,privacy:.public): SET earliest permissable: \(earliestPermissable.standardFormat(),privacy:.public)")
            
            return earliestPermissable
        }
        
        Logger.eviction.warning("ES.\(#function,privacy:.public): Return lastEvictionDate: \(Settings.lastEvictionDate!.standardFormat(),privacy:.public)")
        return Settings.lastEvictionDate!
         */
        let last = Settings.lastEvictionDate
        if last == nil {
            Logger.eviction.warning("ES.\(#function,privacy:.public): Settings.lastEvictionDate:  NIL (1st app launch?)")
        } else {
            Logger.eviction.warning("ES.\(#function,privacy:.public): Return lastEvictionDate: \(last!.standardFormat(),privacy:.public)")
        }
        return last
    }
    
    func nextScheduledEvictionEpoch() -> Date? {
        nextScheduledBgTask
    }
    
    // Assume proposed nextEpoch is already adjusted to potential change in config,
    // meaning it defines the time of the next epoch as lastEpoch + evictionInterval
    func earliestPermittedEvictionDate(for proposed: Date = Date.now) -> Date {
        guard policyIsConfigured() else { return proposed }
        
        if dateIsWithinNoEvictPeriod(proposed) == false { return proposed }
        
        return nextPolicyPeriodEndAfterDate(proposed)
    }
    
    func nextPolicyPeriodEndAfterDate(_ date: Date) -> Date {
        guard policyIsConfigured() else { return date }
        
        let latestDate = max(Date.now, date)
        let latestSeconds = latestDate.localTimeSeconds
        var end = policyPeriodEnd
        if policySpansMidnight() {
            // is now before midnight? add a day
            if latestSeconds > policyPeriodEnd { end += Date.dayInSeconds }
        }
        
        return latestDate.addingTimeInterval(
            TimeInterval(end - latestSeconds)
        )
    }
    
    func currentlyWithinNoEvictPeriod() -> Bool {
        dateIsWithinNoEvictPeriod(Date.now)
    }
    
    func dateIsWithinNoEvictPeriod(_ date: Date) -> Bool {
        guard policyIsConfigured() else { return false}
        
        let dateSeconds = TimeInterval(date.localTimeSeconds)
        if policySpansMidnight() {
            return dateSeconds <= policyPeriodStart || dateSeconds >= policyPeriodEnd
        }
        return  dateSeconds >= policyPeriodStart && dateSeconds <= policyPeriodEnd
    }
    
    func policyIsConfigured() -> Bool {
        policyPeriodStart != policyPeriodEnd
    }
    
    func policySpansMidnight() -> Bool {
        policyPeriodStart > policyPeriodEnd
    }
}
