///
//  EvictionView.swift
//  DittoPOS
//
//  Created by Eric Turner on 5/7/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct EvictionView: View {
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AppConfigView()) {
                    Text("AppConfig Settings")
                }
            }
            
            Section {
                NavigationLink(destination: EvictionLogsView()) {
                    Text("Eviction Logs")
                }
            }
        }
        .navigationTitle("Eviction")
        .interactiveDismissDisabled()
    }
}

#Preview {
    NavigationView {
        EvictionView()
    }
}
