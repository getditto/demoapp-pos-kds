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

struct LocationRowItem: Hashable {
    let locationID: String
    let name: String
    let details: String?
//    init(_ location: Location) {
//        self.locationID = location.id
//        self.name = location.name
//        self.details = location.details
//    }
    init(doc: DittoDocument) {
        self.locationID = doc["_id"].stringValue
        self.name = doc["name"].stringValue
        self.details = doc["details"].string
    }
}

struct LocationRowView: View {
    let rowItem: LocationRowItem
    var id: String { rowItem.locationID }
    var body: some View {
        Text(rowItem.name)
    }
}

class LocationsVM: ObservableObject {
    @ObservedObject var dataVM = DataViewModel.shared
    @Published var selectedItem: LocationRowItem?
    @Published var locationItems = [LocationRowItem]()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        dataVM.$allLocationsDocs
            .sink {[weak self] docs in
                print("LocationsVM.sink --> in map LocationRowItems from location docs")
                self?.locationItems = docs.map { LocationRowItem(doc: $0) }
                self?.selectedItem = self?.locationItems.first(
                    where: { $0.locationID == self?.dataVM.currentLocationId }
                )
            }
            .store(in: &cancellables)
        
        $selectedItem
            .sink {[weak self] item in
                guard let item = item else { return }
                print("LocationsVM.sink selectedItem change")
                if item.locationID != self?.dataVM.currentLocationId {
                    self?.dataVM.currentLocationId = item.locationID
                }
            }
            .store(in: &cancellables)
    }
}

struct LocationsView: View {
    @StateObject var vm = LocationsVM()
        
    var body: some View {
        VStack {
//            Group {
//                if let currentLoc = viewModel.currentLocation {
//                    Text(currentLoc.name)
//                } else {
//                    Text("Please select a location")
//                }
//            }//.frame(maxWidth: .infinity, maxHeight: 32)

            List(vm.locationItems, id: \.self, selection: $vm.selectedItem) { item in
//                Text(loc.name)
                LocationRowView(rowItem: item)
            }
            Spacer()
        }
        .onAppear { print("LocationsView.onAppear") }
        .navigationBarTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
}
