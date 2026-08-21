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
            if viewModel.locations.isEmpty {
                // This is the blocking setup screen until a location is picked,
                // so an empty list would be indistinguishable from a hang.
                // Locations are seeded into the local store on launch, so this
                // shows only until that lands. Deliberately not a fallback to
                // LocationSeed — that would mask a seed that never lands.
                Spacer()
                ProgressView("Loading locations…")
                Spacer()
            } else {
                List(viewModel.locations, id: \.self, selection: viewModel.selectionBinding) { item in
                    LocationRowView(location: item)
                }
                Spacer()
            }
        }
        .navigationBarTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
