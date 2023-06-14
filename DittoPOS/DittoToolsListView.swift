///
//  DittoToolsListView.swift
//  DittoPOS
//
//  Created by Eric Turner on 1/31/23.
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

class DittoToolsVM: ObservableObject {
    @Published var showExportLogsSheet = false
}

struct DittoToolsListView: View {
    @ObservedObject var dittoService = DittoService.shared
    @StateObject private var viewModel = DittoToolsVM()

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Ditto Tools")
                        .frame(width: 400, alignment: .center)
                        .font(.title)
                }
                Section {
                    NavigationLink {
                        PresenceView(ditto: DittoService.shared.ditto)
                    } label: {
                        Text("Presence Viewer")
                    }

                    NavigationLink {
                        PeersListView(ditto: DittoService.shared.ditto)
                    } label: {
                        Text("Peers List")
                    }

                    NavigationLink {
                        DataBrowser(ditto: DittoService.shared.ditto)
                    } label: {
                        Text("Data Browser")
                    }
                    
                    NavigationLink {
                        DittoDiskUsageView(ditto: DittoService.shared.ditto)
                    } label: {
                        Text("Disk Usage")
                    }
                    
                    NavigationLink {
                        LoggingDetailsView($dittoService.loggingOption)
                    } label: {
                        Text("Logging")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExportLogsSheet) {
                ExportLogs()
            }
        }
    }
}

struct DittoToolsListView_Previews: PreviewProvider {
    static var previews: some View {
        DittoToolsListView()
    }
}
