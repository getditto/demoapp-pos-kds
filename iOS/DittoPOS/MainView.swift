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
    @Published var selectedTab: TabViews = MainVM.storedSelectedTab() ?? .locations
    @Published var presentSettingsView = false
    @Published var mainTitle = DittoService.shared.currentLocation?.name ?? "Please Select Location"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
//            print("MainVM.storedSelectedTab: return \(TabViews(rawValue: tabInt)!)")
            return TabViews(rawValue: tabInt)
        }
//        print("MainVM.storedSelectedTab: return NIL")
        return nil
    }
    static func saveSelectedTab(_ tab: TabViews) {
//        print("MainVM.saveSelectedTab: SAVE \(tab)")
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
                
                LocationsView()
                    .tabItem {
                        Label("Locations", systemImage: "globe")
                    }
                    .tag(TabViews.locations)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading ) {
                    Button {
                        vm.presentSettingsView = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $vm.presentSettingsView) {
                SettingsView()
            }
            .onAppear { print("MainView.onAppear") }
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
