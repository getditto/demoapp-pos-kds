///
//  SettingsView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//®
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoDataBrowser
import DittoDiskUsage
import DittoExportLogs
import DittoPresenceViewer
import DittoPeersList
import DittoSwift
import SwiftUI

class SettingsVM: ObservableObject {
//    @ObservedObject var dittoInstance = dittoInstance.shared
    @ObservedObject var dittoInstance = DittoInstance.shared
    @Published var showExportLogsSheet = false
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsVM()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Reset All Data")
                        .onTapGesture {
                            print("RESET ALL DATA - not yet implemented")
                        }
                } header: {
                    Text("App Settings").font(.subheadline)
                }

                Section {
                    NavigationLink {
                        PresenceView(ditto: vm.dittoInstance.ditto)
                    } label: {
                        Text("Presence Viewer")
                    }

                    NavigationLink {
                        PeersListView(ditto: vm.dittoInstance.ditto)
                    } label: {
                        Text("Peers List")
                    }

                    NavigationLink {
                        DataBrowser(ditto: vm.dittoInstance.ditto)
                    } label: {
                        Text("Data Browser")
                    }
                    
                    NavigationLink {
                        DittoDiskUsageView(ditto: vm.dittoInstance.ditto)
                    } label: {
                        Text("Disk Usage")
                    }
                    
                    NavigationLink {
                        LoggingDetailsView($vm.dittoInstance.loggingOption)
                    } label: {
                        Text("Logging")
                    }
                }
                header: {
                    Text("Ditto Tools").font(.subheadline)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $vm.showExportLogsSheet) {
                ExportLogs()
            }
        }
    }
}

struct DittoToolsListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
