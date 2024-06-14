///
//  DittoPOSApp.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import os.log
import SwiftUI

@main
struct DittoPOS: App {
    @Environment(\.scenePhase) var scenePhase
    var evictionService = EvictionService.shared
    
    init() {
        evictionService.registerEvictionBackgroundTask()
        registerNotifications()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                Task {
                    Logger.app.warning("ScenePhase: Enter background at \(Date.now.standardFormat(), privacy: .public)")
                    await evictionService.scheduleBackgroundEvictionIfNeeded()
                }
            case .active:
                Logger.app.info("ScenePhase changed to active at \(Date.now.standardFormat(), privacy: .public)")
                if evictionService.foregroundEvictionNeededNow() {
                    Logger.app.info("Foreground eviction needed!")
                    evictionService.handleForegroundEviction()
                    
                    // eviction runs in a background thread; wait a bit before refreshing orders
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        DittoService.shared.updateOrders()
                    }
                }
            default:
                break
            }
        }
    }
    
    private func registerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                Logger.app.info("Notifications: Authorized")
            } else if let error = error {
                Logger.app.error("\(#function) ERROR: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
