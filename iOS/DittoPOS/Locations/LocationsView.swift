import DittoUI
import SwiftUI

struct LocationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LocationsViewModel
    let onSelect: (String) -> Void

    init(locationsRepository: LocationsRepository, onSelect: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: LocationsViewModel(locationsRepository: locationsRepository))
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            DittoHeader("Select location", location: viewModel.selectedLocation?.name)
            if viewModel.isLoading {
                ProgressView("Loading locations…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.locations.isEmpty {
                DittoEmptyState("No locations available", message: "Demo locations will appear here.", icon: "map-pin")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.locations, id: \.id) { location in
                            Button {
                                onSelect(location.id)
                                dismiss()
                            } label: {
                                DittoRow(location.name, icon: "map-pin", outlined: true) {
                                    if viewModel.selectedLocation?.id == location.id { DittoIcon("check") }
                                    else { DittoIcon("caret-right") }
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(DittoLayout.padding)
                }
            }
        }
        .background(DittoColors.background)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}
