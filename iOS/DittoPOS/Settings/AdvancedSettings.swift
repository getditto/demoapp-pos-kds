//
//  AdvancedSettings.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

struct AdvancedSettings: View {
    @EnvironmentObject var locationsRepository: LocationsRepository

    var body: some View {
        List {
            Section {
                if let locName = locationsRepository.currentLocationId {
                    Text("Current location: \"\(locName)\"")
                } else {
                    Text("No location selected")
                }
            }
        }
    }
}

#Preview {
    AdvancedSettings()
}
