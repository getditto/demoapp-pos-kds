//
//  SettingsView.swift
//  DittoPOS
//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import DittoAllToolsMenu
import DittoSwift
import SwiftUI

struct SettingsView: View {
    private let ditto = DittoManager.shared.ditto

    var body: some View {
        NavigationStack {
            VStack {
                AllToolsMenu(ditto: ditto)

                Text("SDK Version: \(Ditto.version)")
                    .padding()
            }
            .navigationTitle("Ditto Tools")
        }
    }
}

struct DittoToolsListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
