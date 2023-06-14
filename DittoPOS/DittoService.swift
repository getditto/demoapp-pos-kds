///
//  DittoService.swift
//  DittoPOS
//
//  Created by Eric Turner on 2/24/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI

class DittoService: ObservableObject {
    @Published var loggingOption: DittoLogger.LoggingOptions
    private var cancellables = Set<AnyCancellable>()
    
    static var shared = DittoService()
    let ditto: Ditto

    private init() {
        ditto = Ditto(identity: .onlinePlayground(
            appID: Env.DITTO_APP_ID, token: Env.DITTO_PLAYGROUND_TOKEN
        ))

        if let logOption = UserDefaults.standard.object(forKey: "dittoLoggingOption") as? Int {
            self.loggingOption = DittoLogger.LoggingOptions(rawValue: logOption)!
        } else {
            self.loggingOption = DittoLogger.LoggingOptions(
                rawValue: DittoLogger.LoggingOptions.debug.rawValue
            )!
        }
        
        // make sure our log level is set _before_ starting ditto.
        $loggingOption
            .sink {[weak self] option in
                UserDefaults.standard.set(option.rawValue, forKey: "dittoLoggingOption")
                self?.setupLogging(option)
            }
            .store(in: &cancellables)
        
        // Prevent Xcode previews from syncing: non preview simulators and real devices can sync
        let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            try! ditto.startSync()
        }
    }
    
    func setupLogging(_ logOption: DittoLogger.LoggingOptions) {
        switch logOption {
        case .disabled:
            DittoLogger.enabled = false
        default:
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: logOption.rawValue)!
        }
    }
}
