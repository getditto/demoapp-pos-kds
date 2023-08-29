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
    @ObservedObject var dataVM = POS_VM.shared
    var body: some Scene {
        WindowGroup {
            MainView($dataVM.selectedTab)
        }
    }
}
