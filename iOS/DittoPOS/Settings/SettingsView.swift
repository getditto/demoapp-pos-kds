///
//  SettingsView.swift
//
//  Created by Eric Turner on 1/31/23.
//®
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoDataBrowser
import DittoDiskUsage
import DittoExportData
import DittoExportLogs
import DittoPeersList
import DittoPresenceViewer
import DittoPermissionsHealth
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
                Section(header: Text("Viewers")) {
                    NavigationLink(destination: DataBrowser(ditto: ditto)) {
                        DittoToolsListItem(title: "Data Browser", systemImage: "photo", color: .orange)
                    }
                    
                    NavigationLink(destination: PeersListView(ditto: ditto)) {
                            DittoToolsListItem(title: "Peers List", systemImage: "network", color: .blue)
                    }
                    #if !os(tvOS)
                    NavigationLink(destination: PresenceView(ditto: ditto)) {
                        DittoToolsListItem(title: "Presence Viewer", systemImage: "network", color: .pink)
                    }
                    #endif

                    NavigationLink(destination: DittoDiskUsageView(ditto: ditto)) {
                        DittoToolsListItem(title: "Disk Usage", systemImage: "opticaldiscdrive", color: .secondary)
                    }
                    NavigationLink(destination: PermissionsHealth()) {
                        DittoToolsListItem(title: "Permissions Health", systemImage: "exclamationmark.triangle", color: .yellow)
                    }
                }
                Section(header: Text("Exports")) {
                    NavigationLink(destination: LoggingDetailsView(ditto: ditto)) {
                        DittoToolsListItem(title: "Logging", systemImage: "square.split.1x2", color: .green)
                    }

                    // Export Ditto db Directory
                    // N.B. The export Logs feature is in DittoSwiftTools pkg, DittoExportLogs module,
                    // exposed in LoggingDetailsView ^^
                    Button(action: {
                        vm.presentExportDataAlert.toggle()
                    }) {
                        HStack {
                            DittoToolsListItem(title: "Export Data Directory", systemImage: "square.and.arrow.up", color: .green)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sheet(isPresented: $vm.presentExportDataShare) {
                        #if !os(tvOS)
                        ExportData(ditto: ditto)
                        #endif
                    }
                }
                Section("Observability") {
                    NavigationLink(destination: HeartbeatConfig()) {
                        DittoToolsListItem(title: "Heartbeat", systemImage: "heart.fill", color: vm.isHeartbeatOn ? .green : .red)
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
            .alert("Export Ditto Directory", isPresented: $vm.presentExportDataAlert) {
                Button("Export") {
                    vm.presentExportDataShare = true
                }
                Button("Cancel", role: .cancel) {}

                } message: {
                    Text("Compressing log data may take a while.")
                }
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
