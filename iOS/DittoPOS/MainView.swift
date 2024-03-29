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

class MainVM: ObservableObject {
    @Published var selectedTab: TabViews = MainVM.storedSelectedTab() ?? (USE_DEFAULT_LOCATIONS ? .locations : .pos)
    @Published var presentSettingsView = false
    @Published var presentProfileScreen: Bool = false
    @Published var mainTitle = DittoService.shared.currentLocation?.name ?? "Please Select Location"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if !USE_DEFAULT_LOCATIONS {
            self.presentProfileScreen = DittoService.shared.currentLocationId == nil
        }
        
        $selectedTab
            .dropFirst()
            .sink { tab in
                Self.saveSelectedTab(tab)
            }
            .store(in: &cancellables)
        
        // Switch to POS view after location is selected
        DittoService.shared.$currentLocationId
            .dropFirst()
            .sink {[weak self] locId in
                guard let self = self else { return }
                guard let _ = locId else {
                    return
                }
                selectedTab = .pos
            }
            .store(in: &cancellables)
        
        // Update main navbar title with current location name
        DittoService.shared.$currentLocation
            .sink {[weak self] loc in
                guard let self = self else { return }
                guard let loc = loc else { return }
                mainTitle = loc.name
            }
            .store(in: &cancellables)
    }
}

extension MainVM {
    static func storedSelectedTab() -> TabViews? {
        if let tabInt = UserDefaults.standard.storedSelectedTab {
            return TabViews(rawValue: tabInt)
        }
        return nil
    }
    static func saveSelectedTab(_ tab: TabViews) {
        UserDefaults.standard.storedSelectedTab = tab.rawValue
    }
}

struct MainView: View {
    @StateObject private var vm = MainVM()
    @ObservedObject var dittoService = DittoService.shared
    
    var body: some View {
        NavigationStack{
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
                
                if USE_DEFAULT_LOCATIONS {
                    LocationsView()
                        .tabItem {
                            Label("Locations", systemImage: "globe")
                        }
                        .tag(TabViews.locations)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if ENABLE_SETTINGS_VIEW {
                    ToolbarItemGroup(placement: .navigationBarLeading ) {
                        Button {
                            vm.presentSettingsView = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.presentSettingsView) {
                SettingsView()
            }
            .sheet(isPresented: $vm.presentProfileScreen) {
                ProfileScreen()
            }
            .navigationBarTitle(vm.mainTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
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
