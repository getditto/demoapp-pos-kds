///
//  SettingsView.swift
//
//  Created by Eric Turner on 1/31/23.
//®
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoAllToolsMenu
import DittoSwift
import SwiftUI


@MainActor class SettingsVM: ObservableObject {
    @Published var presentExportDataShare: Bool = false
    @Published var presentExportDataAlert: Bool = false
    @Published var isHeartbeatOn: Bool = Settings.isHeartbeatOn
}

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = SettingsVM()
    @ObservedObject var dittoService = DittoService.shared
    private let ditto = DittoService.shared.ditto
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        NavigationView {
            List{
                Section(header: Text("Debugging")) {
                    NavigationLink(destination: AllToolsMenu(ditto: ditto)) {
                        DittoToolsListItem(title: "Ditto Tools", systemImage: "network", color: .orange)
                    }
                }
                Section {
                    NavigationLink(destination: AdvancedSettings()) {
                        DittoToolsListItem(title: "Advanced Settings", systemImage: "gear", color: .teal)
                    }
                }
            }
            #if !os(tvOS)
            .listStyle(InsetGroupedListStyle())
            #else
            .listStyle(.grouped)
            #endif
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationTitle("Ditto Tools")
            }
        
        Spacer()
    
        VStack {
            Text("SDK Version: \(ditto.sdkVersion)")
        }.padding()
    }
}


struct DittoToolsListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
