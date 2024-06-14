///
//  MainView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/6/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import OSLog
import SwiftUI

enum TabViews: Int, Identifiable {
    case pos=1, kds, locations
    var id: Self { self }
}

class MainVM: ObservableObject {
    @Published var selectedTab: TabViews
    @Published var presentSettingsView = false
    @Published var presentCustomLocationScreen = false
    @Published var presentLocationChooserAlert = false
    @Published var mainTitle = DittoService.shared.currentLocation?.name ?? "Please Select Location"
    private var cancellables = Set<AnyCancellable>()
    private var dittoService = DittoService.shared
    
    init() {
        if Settings.locationId == nil && Settings.useDemoLocations {
            selectedTab = .locations
        } else {
            selectedTab = Settings.selectedTabView ?? .pos
        }

        Settings.useDemoLocationsPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink {[weak self] enabled in
                guard let self = self else { return }
                
                presentSettingsView = false
                
                if enabled {
                    withAnimation {[weak self] in
                        self?.presentCustomLocationScreen = false
                        self?.selectedTab = .locations
                    }
                } else {
                    withAnimation{[weak self] in
                        self?.selectedTab = .pos
                        self?.presentCustomLocationScreen = true
                    }
                }
            }
            .store(in: &cancellables)
        
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
                    mainTitle = loc?.name ?? "Please Select Location"
            }
            .store(in: &cancellables)
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
                    .sheet(isPresented: $vm.presentCustomLocationScreen) {
                        CustomLocationScreen()
                    }
                
                KDSView()
                    .tabItem {
                        Label("KDS", systemImage: "square.grid.3x1.below.line.grid.1x2")
                    }
                    .tag(TabViews.kds)

                if Settings.useDemoLocations {
                    LocationsView()
                        .tabItem {
                            Label("Locations", systemImage: "globe")
                        }
                        .tag(TabViews.locations)
                }
            }
            .sheet(isPresented: $vm.presentSettingsView) {
                SettingsView()
            }
            .onAppear {
                if dittoService.locationSetupNotValid {
                    vm.presentLocationChooserAlert = true
                }
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
            .navigationBarTitle(vm.mainTitle)
//            .navigationBarTitle("\(DittoService.shared.currentLocation?.name ?? "Please Select Location") (Logs: \(Settings.evictionLogs.count))")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .alert("Store Location Options", isPresented: $vm.presentLocationChooserAlert, actions: {
                Button("Demo Locations")  {
                    withAnimation {
                        dittoService.updateLocationsSetup(option: .demo)
                    }
                }
                Button("Custom Location") {
                    dittoService.updateLocationsSetup(option: .custom)
                    vm.presentCustomLocationScreen = true
                }
                }, message: {
                    Text(
                        "Choose demo restaurant locations and switch between them, or "
                        + "create your own custom location."
                    )
                })
        }
    }
    
//    var barTitle: String {
//        dittoService.currentLocation?.name ?? "Please Select Location"
//    }
//    //TEST
//    func aBarTitle() -> String {
//        if let locName = dittoService.currentLocation?.name {
//            return locName + "(Logs: \(Settings.evictionLogs.count))"
//        }
//        return dittoService.currentLocation?.name ?? "Please Select Location"
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
