///
//  EvictionLogger.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/24/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import DittoSwift
import Foundation
import OSLog

enum EvictionMode: String {
    case undefined, background, foreground, forced, test
    var isForced: Bool { self == .forced }
    var isTest: Bool { self == .test }
}

/// Container for bundling eviction query attributes for logging
struct EvictionLogBundle {
    let query: String
    let queryKey: String
    var queryTimestamp: String
    var opMode: EvictionMode
    var docIDs: [DittoSwift.DittoDocumentID] = []
    var resultMsg: String = ""
    var details: [String:String] = [:] //optional addtional details
    var epoch: String //cycle of eviction queries date - matches Settings.lastEvictionDate
}

/// Eviction log model
struct EvictionLog: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    let query: String
    var opMode: String
    var resultMsg: String = ""
    var details: String = ""
    var docIDs: String = ""
    var queryTimestamp: String // use this iso string to sort
    var epochTimestamp: String
    
    var opTime: String {
        Date.fromIsoString(queryTimestamp)?.standardFormat() ?? "[opTime N/A]"
    }
    
    func formattedTitle(collName: String) -> String {
        let mode = "\(opMode.capitalized) Eviction"
        let formatTitle = "[\(collName)]: \(mode) eviction (\(docIDs.count))"
        return formatTitle
    }
    
    struct Keys {
        static var query = "query"
        static var docIDs = "docIDs"
    }
    
    // for Xcode preview in EvictionLogsView
    static var previewLog: EvictionLog {
        let timestamp = Date.now.isoString()

        let query =  """
        EVICT FROM COLLECTION `orders` (saleItemIds MAP, transactionIds MAP)
        WHERE createdOn <= '\(timestamp)'
        """
        var log = EvictionLog(
            title: "",
            query: query,
            opMode: EvictionMode.background.rawValue,
            queryTimestamp: timestamp,
            epochTimestamp: timestamp
        )
        log.title = log.formattedTitle(collName: ordersKey)

        return log
    }
}

struct EvictionLogger {
    
    func addAbortLog(msg: String, mode: EvictionMode, details: [String:String] = [:]) {
        let modeTitle = "\(mode.rawValue.capitalized)"
        
        let log = EvictionLog(
            title: "\(modeTitle) Eviction Aborted",
            query: "N/A",
            opMode: mode.rawValue,
            resultMsg: msg,
            details: details.isEmpty ? "N/A" : formattedDetails(details),
            docIDs: "N/A",
            queryTimestamp: Date.now.isoString(),
            epochTimestamp: "N/A"
        )
        addToLogs(log)
//        let logs = (Settings.evictionLogs ?? []) + [log]
//        Settings.evictionLogs = logs
//        Logger.eviction.debug("Save eviction log at \(Date.now.standardFormat(),privacy:.public)")
    }
    
    func addLog(bundle: EvictionLogBundle) {
        let modeTitle = "\(bundle.opMode.rawValue.capitalized)"
        
        let log = EvictionLog(
            title: "[\(bundle.queryKey)] \(modeTitle) Eviction (\(bundle.docIDs.count))",
            query: bundle.query,
            opMode: bundle.opMode.rawValue,
            resultMsg: bundle.resultMsg,
            details: bundle.details.isEmpty ? "[none]" : formattedDetails(bundle.details),
            docIDs: formattedDocIDs(bundle.docIDs),
            queryTimestamp: bundle.queryTimestamp,
            epochTimestamp: bundle.epoch
        )
        addToLogs(log)
//        let logs = (Settings.evictionLogs ?? []) + [log]
//        Settings.evictionLogs = logs
//        Logger.eviction.debug("Save eviction log at \(Date.now.standardFormat(),privacy:.public)")
    }

    /* why aren't there logs anymore? because it's another task off background task? */
    private func addToLogs(_ log: EvictionLog) {
        let log = log
        Task {
            let logs = (Settings.evictionLogs ?? []) + [log]
            
            Logger.eviction.debug("Save eviction log at \(Date.now.standardFormat(),privacy:.public)")
            
            Settings.evictionLogs = logs
        }
    }
    
    private func formattedDocIDs(_ ids: [DittoSwift.DittoDocumentID]) -> String {
        ids.map { $0.toString() }.joined(separator: "\n")
    }
    
    private func formattedDetails(_ dict: [String:String]) -> String {
        guard dict.count > 0 else { return "" }
        let keys = dict.keys.sorted(by: <)
        let details = keys.map { "\($0): \(dict[$0]!)" }.joined(separator: "\n")
        return details
    }
}
