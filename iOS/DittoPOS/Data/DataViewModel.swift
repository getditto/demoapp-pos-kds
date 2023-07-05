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
    
    @Published var menuItems: [MenuItem] = MenuItem.demoItems // for menu display
//    @Published var locations = [Location]() // all locations for list selection
//    @Published var orders = [Order]() // all orders for KDS(?)
    @Published var currentLocation: Location?
    private var currentLocationPublisher: AnyPublisher<Location?, Never>
    
    @Published var currentOrder: Order?
    private var currentOrderPublisher: AnyPublisher<Order?, Never>

    @Published var currentOrderItems = [OrderItem]()
    
    private var cancellables = Set<AnyCancellable>()
    private let dittoService = DittoService.shared
    
    static var shared = DataViewModel()
    
    private init() {
        self.currentLocationPublisher = dittoService.currentLocationPublisher()
        self.currentOrderPublisher = dittoService.currentOrderPublisher()
        
        setupDemoLocations()
        
        currentLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink {[weak self] loc in
                if let loc = loc {
                    print("DVM.init(): currentLocationPublisher fired with \(loc.name)")
                    self?.currentLocation = loc
                    if loc.orderIds.isEmpty {
                        DispatchQueue.main.async {
                            print("DVM.init(): currentLocationPublisher - CALL to create/add NEW ORDER")
                            self?.dittoService.addOrderToLocation(Order.new(locationId: loc.id))
                        }
                    }
                }
            }
            .store(in: &cancellables)

        currentOrderPublisher
            .receive(on: DispatchQueue.main)
            .sink {[weak self] order in
                guard let order = order else {
                    print("DVM.$currentOrderPublisher.sink: WARNING received NIL order --> RETURN")
                    return
                }
                print("DVM.$currenOrderPublisher: order changed: \(order)")
                var items = [OrderItem]()
                for (timestamp, id) in order.orderItems {
                    if let menuItem = self?.menuItem(for: id) {
                        var orderItem = OrderItem(menuItem: menuItem)
                        orderItem.createdOn = DateFormatter.isoDate.date(from: timestamp)!
                        items.append(orderItem)
                    }
                }
                self?.currentOrderItems = items.sorted(by: { $0.createdOn < $1.createdOn })
                self?.currentOrder = order
            }
            .store(in: &cancellables)
        
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
            .receive(on: DispatchQueue.main)
            .sink {[weak self] id in
                if !id.isEmpty {
//                    print("DVM.$currentLocationId.sink: currentLocationId not empty --> call setupCurrentLocation")
                    self?.dittoService.currentLocationId = id
                    self?.saveLocationID(id)
                }
            }
            .store(in: &cancellables)
        
        dittoService.$allLocationDocs
            .receive(on: DispatchQueue.main)
            .assign(to: &$allLocationDocs)
        
//        $currentOrder // update currentOrderItems / TODO: transactions
//            .sink {[weak self] order in
//                print("DVM.$currentOrder.sink: orderDoc.orderItems: \()")
//            }
//            .store(in: &cancellables)
        
//        $currentLocation
//            .sink {loc in //[weak self] loc in
//                print("DVM.$currentLocation: loc changed: \(loc.debugDescription )")
//            }
//            .store(in: &cancellables)
    }    
    
    func addOrderItem(_  menuItem: MenuItem) {
        //TODO: alert user to select location
        guard let curOrder = currentOrder else { print("Cannot add item: current order is NIL\n\n"); return }
        
//        let orderItem = OrderItem(orderId: currentOrder!.id, menuItemId: menuItem.id, price: menuItem.price)
        let orderItem = OrderItem(menuItem: menuItem)
        print("DVM.\(#function): CALL DS to add OrderItem: \(orderItem)")
        dittoService.addItemToOrder(item: orderItem, order: curOrder)
    }
    
    func currentOrderTotal() -> Double {
        guard let _ = currentOrder else { return 0.0 }
        return currentOrderItems.sum(\.price.amount)
    }
    
    func menuItem(for id: String) -> MenuItem {
        menuItems.first( where: { $0.id == id } )!
    }
    
    func setupDemoLocations() {
        for loc in Location.demoLocations {
            try! dittoService.locationDocs.upsert(
                loc.docDictionary()
//                writeStrategy: .insertDefaultIfAbsent
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
