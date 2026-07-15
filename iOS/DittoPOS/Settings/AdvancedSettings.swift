//
//  AdvancedSettings.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

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
