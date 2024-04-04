//
//  LogFileConfig.swift
//  DittoPOS
//
//  Created by Walker Erekson on 3/12/24.
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Foundation

struct LogFileConfig {
    static let logsDirectoryName = "debug-logs"
    static let logFileName = "logs.txt"
    static let zippedLogFileName = "logs.zip"

    static var logsDirectory: URL! = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }()

    static var logFileURL: URL! = {
        return Self.logsDirectory.appendingPathComponent(logFileName)
    }()
    
    public static func createLogFileURL() -> URL? {
        do {
            try FileManager().createDirectory(at: self.logsDirectory,
                                              withIntermediateDirectories: true)
        } catch let error {
            assertionFailure("Failed to create logs directory: \(error)")
            return nil
        }

        return self.logFileURL
    }
}
