///
//  DataViewModel.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/16/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import Foundation

class DataViewModel: ObservableObject {
    @Published var allLocationsDocs = [DittoDocument]()
    @Published var currentLocationId: String = ""
    @Published var selectedTab: TabViews = .locations
    
//    @Published var locations = [Location]() // all locations for list selection
//    @Published var orders = [Order]() // all orders for KDS(?)
    @Published var currentLocation: Location?
    @Published var currentOrder: Order?
    @Published var menuItems: [MenuItem] = MenuItem.demoItems // for menu display
    @Published var orderItems = [MenuItem]()
    
    private var cancellables = Set<AnyCancellable>()
    private let dittoService = DittoService.shared
    
    static var shared = DataViewModel()
    
    private init() {
        if let _ = storedLocationId(), let tab = storedSelectedTab() {
            print("DVM.\(#function): stored locationId && stored selectedTab found -> SET selectedTab: \(tab)")
            selectedTab = tab
        }

        $selectedTab
            .sink {[weak self] tab in
                print("DVM.$selectedTab: SAVE selectedTab: \(tab)")
                self?.saveSelectedTab(tab)
            }
            .store(in: &cancellables)
        
        dittoService.$allLocationsDocs
            .assign(to: &$allLocationsDocs)

        $currentLocationId
            .sink {[weak self] id in
                if !id.isEmpty {
                    self?.setupCurrentLocation(id: id)
                    // Following code is to automatically switch tab view after location selection
//                    if let storedTab = self?.storedSelectedTab() {
//                        DispatchQueue.main.async {[weak self] in
//                            print("DataVM. currentLocationID.sink - stored Tab: \(storedTab))")
//                            self?.selectedTab = TabViews.pos//storedTab == TabViews.locations.rawValue ? TabViews.pos.rawValue : storedTab
//                            print("DataVM. currentLocationID.sink - set selectedTab: \(self!.selectedTab))")
//                        }
//                    } else {
//                        self?.selectedTab = .locations
//                        print("DataVM. currentLocationID.sink - SET selectedTab \(self!.selectedTab)")
//                    }
                }
            }
            .store(in: &cancellables)
        
        print("DVM.\(#function): SET currentLocationId to storedLocation() or NIL")
        self.currentLocationId = storedLocationId() ?? ""
        
        setupDemoLocations()
        
    }
    
    func setupCurrentLocation(id: String) {
        guard !id.isEmpty else { return }
        
        if let doc = dittoService.locationDocs.findByID(id).exec() {
            let loc = Location(doc: doc)
            self.currentLocation = loc
            saveLocationID(id)
            setupCurrentOrder(location: loc)
        }
    }
    
    func setupCurrentOrder(location: Location) {
        // set current order or create new if needed
        if location.orderIds.isEmpty {
            let order = Order.new(locationId: location.id)
            self.currentOrder = order
        } else {
            self.currentOrder = orders(for: location).first ?? nil
        }
    }
    
    
    func addOrderItem(_  item: MenuItem) {
        guard var _ = currentOrder else { print("Cannot add item: current order is NIL\n\n"); return }
        orderItems.append(item)
    }
    
    func currentOrderTotal() -> Double {
        guard let _ = currentOrder else { return 0.0 }
        return orderItems.sum(\.price.amount)
    }
    
    //    func menuItemFor(id: String) -> MenuItem? {
    //        menuItems.first(where: { $0.id == id })
    //    }
    
    /*
    func setupLocation(_ loc: Location) {
        // get previously selected location if saved
        if var storedLocation = getStoredLocation() {
            // TMP: create a new empty order if location has no existing orders
            if storedLocation.orderIDs.isEmpty {
                let order = Order(
                    id: UUID().uuidString,
                    locationID: storedLocation.id,
                    createdOn: Date(),
                    status: .incomplete
                )
                self.currentOrder = order
                
                storedLocation.orderIDs = [order.id: DateFormatter.isoDate.string(from: order.createdOn)]
            }
            self.currentLocation = storedLocation
        }
    }
     */
    
    func orders(for loc: Location) -> [Order] {
        dittoService.orders(for: loc)
    }
    
    func setupDemoLocations() {
        for loc in Location.demoLocations {
            try! dittoService.locationDocs.upsert(
                loc.docDictionary(),
                writeStrategy: .insertDefaultIfAbsent
            )
        }
    }
}


// Local Storage
extension DataViewModel {
    func storedLocationId() -> String? {
        UserDefaults.standard.storedLocationId
    }
    func saveLocationID(_ newId: String) {
        UserDefaults.standard.storedLocationId = newId
    }

    func storedSelectedTab() -> TabViews? {//Int? {
        if let tabInt = UserDefaults.standard.storedSelectedTab {
            print("DVM.\(#function): return: \(tabInt)")
            return TabViews(rawValue: tabInt)
        }
        print("DVM.\(#function): return nil")
        return nil
    }
    func saveSelectedTab(_ tab: TabViews) {//Int) {
        print("DVM.\(#function): store: \(tab)")
        UserDefaults.standard.storedSelectedTab = tab.rawValue
    }

    /*
    func getStoredLocation() -> Location? {
        UserDefaults.standard.storedLocation
    }

    func storeLocation(_ loc: Location?) {
        UserDefaults.standard.storedLocation = loc
    }
    
    func getCurrentOrder() -> Order? {
        UserDefaults.standard.currentOrder
    }
    
    func saveCurrentOrder(_ order: Order) {
        UserDefaults.standard.currentOrder = order
    }
     */
}
