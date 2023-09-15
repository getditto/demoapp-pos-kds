///
//  DittoPOSApp.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

@main
struct DittoPOS: App {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .onChange(of: scenePhase) { newScenePhase in
              switch newScenePhase {
              case .active:
                print("")
              case .inactive:
                  print("")
              case .background:
                print("--------------------- App has gone to background ---------------------")
                  DittoService.shared.purgeOldOrders()
              @unknown default:
                  print("Oh - interesting: an unexpected new value: \(newScenePhase)")
              }
        }
    }
}
