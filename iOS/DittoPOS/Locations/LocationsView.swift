///
//  LocationsView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI

struct LocationRowView: View {
    let location: Location
    var id: String { location.id }
    var body: some View {
        Text(location.name)
    }
}

@MainActor class LocationsVM: ObservableObject {
    @ObservedObject var dataVM = DittoService.shared
    @Published var selectedItem: Location?
    @Published var locations = [Location]()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        dataVM.$allLocations
            .sink { [weak self] locations in
                self?.locations = locations
                self?.selectedItem = locations.first(
                    where: { $0.id == self?.dataVM.currentLocationId }
                )
            }
            .store(in: &cancellables)
        
        $selectedItem
            .sink {[weak self] item in
                guard let item = item else { return }
                if item.id != self?.dataVM.currentLocationId {

                    // Important: this must be called before setting dittoService.currentLocationId
                    // because POS_VM listens to reset incomplete orders before changing location
                    NotificationCenter.default.post(
                        name: Notification.Name("willUpdateToLocationId"),
                        object: item.id
                    )
                    
                    print("LocationsVM.$selectedItem.sink --> SET dittoService.currentLocationId: \(item.id)")
                    self?.dataVM.currentLocationId = item.id
                }
            }
            .store(in: &cancellables)
    }
}

struct LocationsView: View {
    @StateObject var vm = LocationsVM()
        
    var body: some View {
        VStack {
            List(vm.locations, id: \.self, selection: $vm.selectedItem) { item in
                LocationRowView(location: item)
            }
            Spacer()
        }
//        .onAppear { print("LocationsView.onAppear") }
        .navigationBarTitle("Locations")
        #if !os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
}
