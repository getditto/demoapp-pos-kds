///
//  LocationsView.swift
//  DittoPOS
//
//  Created by Eric Turner on 6/15/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI

struct LocationRowView: View {
    let location: Location
    var id: String { location.id }
    var body: some View {
        Text(location.name)
    }
}

struct LocationsView: View {
    @StateObject private var viewModel: LocationsViewModel

    init(locationsRepository: LocationsRepository) {
        _viewModel = StateObject(wrappedValue: LocationsViewModel(locationsRepository: locationsRepository))
    }

    var body: some View {
        VStack {
            List(viewModel.locations, id: \.self, selection: viewModel.selectionBinding) { item in
                LocationRowView(location: item)
            }
            Spacer()
        }
        .navigationBarTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
