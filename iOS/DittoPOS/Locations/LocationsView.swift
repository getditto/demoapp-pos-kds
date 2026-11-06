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
    private let title: String

    init(locationsRepository: LocationsRepository, title: String = "Locations") {
        _viewModel = StateObject(wrappedValue: LocationsViewModel(locationsRepository: locationsRepository))
        self.title = title
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading locations…")
                Spacer()
            } else if viewModel.locations.isEmpty {
                Text("No locations available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.locations, id: \.self, selection: viewModel.selectionBinding) { item in
                    LocationRowView(location: item)
                }
                Spacer()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
