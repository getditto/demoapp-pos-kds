///
//  ContentView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoDataBrowser
import DittoDiskUsage
import DittoExportLogs
import DittoPresenceViewer
import DittoSwift
import SwiftUI

class ContentVM: ObservableObject {
    @Published var presentSettingsView = false
}

struct ContentView: View {
    @StateObject private var viewModel = ContentVM()

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading ) {
                    Button {
                        viewModel.presentSettingsView = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $viewModel.presentSettingsView) {
                DittoToolsListView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
