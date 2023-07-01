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
    @Published var allLocationDocs = [DittoDocument]()
    @Published var selectedLocationId: String = ""
    @Published var selectedTab: TabViews = .locations
    
//    @Published var locations = [Location]() // all locations for list selection
//    @Published var orders = [Order]() // all orders for KDS(?)
    @Published var currentLocation: Location?
    private var currentLocationPublisher: AnyPublisher<Location?, Never>
    @Published var currentOrder: Order?
    @Published var currentOrderItems = [MenuItem]()
    @Published var menuItems: [MenuItem] = MenuItem.demoItems // for menu display
    
    private var cancellables = Set<AnyCancellable>()
    private let dittoService = DittoService.shared
    
    static var shared = DataViewModel()
    
    private init() {
        self.currentLocationPublisher = dittoService.currentLocationPublisher()
        currentLocationPublisher
            .sink {[weak self] loc in
                if let loc = loc {
                    print("DVM.init(): currentLocationPublisher fired with \(loc.name)")
                    self?.currentLocation = loc
                    self?.setupCurrentOrder(location: loc)
                }
            }
            .store(in: &cancellables)

        setupDemoLocations()
        
        if let selectedLocId = storedLocationId() {
            print("DVM.\(#function): SET currentLocationId to storedLocation() or NIL")
            self.selectedLocationId = selectedLocId
            self.dittoService.currentLocationId = selectedLocId
        }
        
        // Set stored selected tab if we have a locationId, else it will default to Locations tab
        if let _ = storedLocationId(), let tab = storedSelectedTab() {
//            print("DVM.\(#function): stored locationId && stored selectedTab found -> SET selectedTab: \(tab)")
            selectedTab = tab
        }

        $selectedTab
            .sink {[weak self] tab in
//                print("DVM.$selectedTab.sink: SAVE selectedTab: \(tab)")
                self?.saveSelectedTab(tab)
            }
            .store(in: &cancellables)
                
        $selectedLocationId
            .sink {[weak self] id in
                if !id.isEmpty {
//                    print("DVM.$currentLocationId.sink: currentLocationId not empty --> call setupCurrentLocation")
                    self?.dittoService.currentLocationId = id
                }
            }
            .store(in: &cancellables)
        
        dittoService.$allLocationDocs
            .assign(to: &$allLocationDocs)
        
    }
    
    
//    func setupCurrentLocation(id: String) {
//        guard !id.isEmpty else { print("DVM.\(#function) location id isEmpty -> return"); return }
//        
//        if let doc = dittoService.locationDocs.findByID(id).exec() {
//            let loc = Location(doc: doc)
//            self.currentLocation = loc
//            saveLocationID(id)
//            setupCurrentOrder(location: loc)
//        }
//    }
    
    func setupCurrentOrder(location: Location) {
        // set current order or create new if needed
        if location.orderIds.isEmpty {
            let order = Order.new(locationId: location.id)
            self.currentOrder = order
            do {
                try dittoService.orderDocs.upsert(order.docDictionary())
                
                var location = location
                location.orderIds[order.id] = order.createdOnStr
                dittoService.addOrderToLocation(order)
                
//                print("CHECK: saved orderDoc: \(String(describing: dittoService.orderDoc(for: order)))")
//                print("CHECK: saved locationDoc: \(String(describing: dittoService.locationDocs.findByID(location.id).exec()))")
                
                self.currentLocation = location
            } catch {
                print("Error upserting order with title: \(order.title)")
            }
        } else {
            self.currentOrder = dittoService.orders(for: location).first
        }
    }
    
    
    func addOrderItem(_  item: MenuItem) {
        guard var _ = currentOrder else { print("Cannot add item: current order is NIL\n\n"); return }
        currentOrderItems.append(item)
    }
    
    func currentOrderTotal() -> Double {
        guard let _ = currentOrder else { return 0.0 }
        return currentOrderItems.sum(\.price.amount)
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

    func storedSelectedTab() -> TabViews? {
        if let tabInt = UserDefaults.standard.storedSelectedTab {
//            print("DVM.\(#function): return: \(tabInt)")
            return TabViews(rawValue: tabInt)
        }
        print("DVM.\(#function): return nil")
        return nil
    }
    func saveSelectedTab(_ tab: TabViews) {
//        print("DVM.\(#function): store: \(tab)")
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
