///
//  AdvancedSettings.swift
//  DittoPOS
//
//  Created by Eric Turner on 3/7/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI


struct AdvancedSettings: View {
    var body: some View {
        List {
            Section {
                if let locName = Settings.locationId {
                    Text("Current location: \"\(locName)\"")
                } else {
                    Text("No location selected")
                }
            }

            Section {
                Button("Reset Location") {
                    DittoService.shared.resetLocationSelection()
                }
            }
        }
    }
}

#Preview {
    AdvancedSettings()
}
