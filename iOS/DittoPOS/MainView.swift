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
    case pos=1, kds, locations
    var id: Self { self }
}

@MainActor class MainVM: ObservableObject {
    @Published var selectedTab: TabViews
    @Published var presentSettingsView = false
    @Published var mainTitle = DittoService.shared.currentLocation?.name ?? "Please Select Location"
    private var cancellables = Set<AnyCancellable>()
    private var dittoService = DittoService.shared

    init() {
        if Settings.locationId == nil {
            selectedTab = .locations
        } else {
            selectedTab = Settings.selectedTabView ?? .pos
        }

        $selectedTab
            .dropFirst()
            .sink { tab in
                Settings.selectedTabView = tab
            }
            .store(in: &cancellables)

        // Switch to POS view after location is selected
        dittoService.$currentLocationId
            .dropFirst()
            .sink {[weak self] locId in
                guard let self = self, locId != nil else { return }
                selectedTab = .pos
            }
            .store(in: &cancellables)
        
        // Update main navbar title with current location name
        dittoService.$currentLocation
            .sink {[weak self] loc in
                guard let self = self else { return }
                if let loc = loc {
                    mainTitle = loc.name
                } else {
                    mainTitle = "Please Select Location"
                }
            }
            .store(in: &cancellables)
    }
}

struct MainView: View {
    @StateObject private var vm = MainVM()
    @ObservedObject var dittoService = DittoService.shared
    
    var body: some View {
        NavigationStack {
            TabView(selection: $vm.selectedTab) {
                POSView()
                    .tabItem {
                        Label("POS", systemImage: "dot.squareshape")
                    }
                    .tag(TabViews.pos)

                KDSView()
                    .tabItem {
                        Label("KDS", systemImage: "square.grid.3x1.below.line.grid.1x2")
                    }
                    .tag(TabViews.kds)

                LocationsView()
                    .tabItem {
                        Label("Locations", systemImage: "globe")
                    }
                    .tag(TabViews.locations)
            }
            .sheet(isPresented: $vm.presentSettingsView) {
                SettingsView()
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading ) {
                    Button {
                            vm.presentSettingsView = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            #if !os(tvOS)
            .navigationBarTitle(vm.mainTitle)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                if dittoService.locationSetupNotValid {
                    dittoService.resetLocationSelection()
                    vm.selectedTab = .locations
                }
            }
        }
    }
    
    var barTitle: String {
        dittoService.currentLocation?.name ?? "Please Select Location"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
