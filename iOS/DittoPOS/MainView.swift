///
//  MainView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import SwiftUI

enum TabViews: Int, Identifiable {
    case pos, kds, locations
    var id: Self { self }
}

class MainVM: ObservableObject {
    @Published var presentSettingsView = false
    private var cancellables = Set<AnyCancellable>()
}

struct MainView: View {
    @StateObject private var viewModel = MainVM()
    @Binding var selectedTab: TabViews
    init(_ tab: Binding<TabViews>) {
        self._selectedTab = tab
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            POSView()
                .tabItem {
                    Label("POS", systemImage: "dot.squareshape")
                }
                .tag(TabViews.pos)//.rawValue)
//                .tag(0)
            
            KDSView()
                .tabItem {
                    Label("KDS", systemImage: "square.grid.3x1.below.line.grid.1x2")
                }
                .tag(TabViews.kds)//.rawValue)
//                .tag(1)
            
            LocationsView()
                    .tabItem {
                    Label("Locations", systemImage: "globe")
                }
                .tag(TabViews.locations)//.rawValue)
//                    .tag(2)
            }
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
                SettingsView()
            }
            .onAppear { print("MainView.onAppear") }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(.constant(DataViewModel.shared.selectedTab))
//        MainView()
    }
}
