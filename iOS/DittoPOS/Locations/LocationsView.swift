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
    @ObservedObject var dataVM = DittoService.shared
    @Published var selectedItem: LocationRowItem?
    @Published var locationItems = [LocationRowItem]()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        dataVM.$allLocationDocs
            .sink {[weak self] docs in
                self?.locationItems = docs.map { LocationRowItem(doc: $0) }
                self?.selectedItem = self?.locationItems.first(
                    where: { $0.locationID == self?.dataVM.currentLocationId }
                )
            }
            .store(in: &cancellables)
        
        $selectedItem
            .sink {[weak self] item in
                guard let item = item else { return }
                if item.locationID != self?.dataVM.currentLocationId {
                    print("LocationsVM.$selectedItem.sink --> SET dittoService.currentLocationId: \(item.locationID)")
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
            List(vm.locationItems, id: \.self, selection: $vm.selectedItem) { item in
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
