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
    @Published var selectedTab: TabViews = .locations
    
    @Published var allLocationDocs = [DittoDocument]()
    @Published var selectedLocationId: String = ""

    @Published var currentLocation: Location?
    private var currentLocationPublisher: AnyPublisher<Location?, Never>
    
    @Published var currentOrder: Order?
    private var currentOrderPublisher: AnyPublisher<Order?, Never>

    @Published var menuItems: [MenuItem] = MenuItem.demoItems // for menu display
    @Published var currentOrderItems = [OrderItem]()
    
    private var cancellables = Set<AnyCancellable>()
    private let dittoService = DittoService.shared
    
    static var shared = DataViewModel()
    
    @Published var test: String = ""
    
    private init() {
        self.currentLocationPublisher = dittoService.currentLocationPublisher()
        self.currentOrderPublisher = dittoService.currentOrderPublisher()
        
        setupDemoLocations()
        
        //------------------------------------------------------------------------------------------
        // TEST
        $test.sink { str in
            print("DVM.$test.sink: change to \(str)")
        }
        .store(in: &cancellables)
        //------------------------------------------------------------------------------------------
        
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
//                print("DVM.$currenOrderPublisher: order changed: \(order)")
                var items = [OrderItem]()
//                for (timestamp, id) in order.orderItems {
                for (compoundStringId, menuItemId) in order.orderItems {
//                    if let menuItem = self?.menuItem(for: id) {
                    if let menuItem = self?.menuItem(for: menuItemId) {
                        let orderItem = OrderItem(id: compoundStringId, menuItem: menuItem)
//                        orderItem.createdOn = DateFormatter.isoDate.date(from: timestamp)!
                        print("DVM.$currenOrderPublisher: orderItem --> OUT: \(orderItem.id)")
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
                    self?.saveLocationId(id)
                }
            }
            .store(in: &cancellables)
        
        dittoService.$allLocationDocs
            .receive(on: DispatchQueue.main)
            .assign(to: &$allLocationDocs)
        
    }
    
    func addOrderItem(_  menuItem: MenuItem) {
        //TODO: alert user to select location
        guard var curOrder = currentOrder else { print("Cannot add item: current order is NIL\n\n"); return }
        
        let orderItem = OrderItem(menuItem: menuItem)
//        print("DVM.\(#function): CALL DS to add OrderItem: \(orderItem)")
        print("DVM.\(#function): orderItem --> IN: \(orderItem.id)")
        // set order status to inProcess for every item added
        curOrder.status = .inProcess
        dittoService.addItemToOrder(item: orderItem, order: curOrder)
    }
    
    
    func payCurrentOrder() {
        guard let loc = currentLocation, let order = currentOrder else {
            print("DVM.\(#function): ERROR - either current Location or Order is nil --> return")
            return
        }
        let tx = Transaction.new(
            locationId: loc.id,
            orderId: order.id,
            amount: currentOrderTotal()
        )
//        // set order status to next
//        let status = order.status.rawValue + 1 //N.B. not checking for out-of-bounds condition
//        order.status = OrderStatus(rawValue: status)!
        dittoService.updateOrder(order, with: tx)
        
        if let loc = currentLocation {
            // wait a second to show current order updated to PAID
            // then create new order automatically
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[weak self] in
                print("DVM.\(#function): ORDER PAID - CALL to create/add NEW ORDER")
                self?.dittoService.addOrderToLocation(Order.new(locationId: loc.id))
            }
        }
    }
    
    func cancelCurrentOrder() {
        print("DVM.\(#function): NOT YET IMPLEMENTED")
    }
    
    //MARK: Utilities
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
    func saveLocationId(_ newId: String) {
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
