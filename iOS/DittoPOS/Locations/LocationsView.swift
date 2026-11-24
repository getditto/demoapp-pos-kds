import AppUI
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
            AppHeader("Select location", location: viewModel.selectedLocation?.name)
            if viewModel.isLoading {
                ProgressView("Loading locations…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.locations.isEmpty {
                AppEmptyState("No locations available", message: "Demo locations will appear here.", icon: "map-pin")
            } else {
                ScrollView {
                    VStack(spacing: AppLayout.mediumGap) {
                        ForEach(viewModel.locations, id: \.id) { location in
                            Button {
                                onSelect(location.id)
                                dismiss()
                            } label: {
                                AppRow(location.name, icon: "map-pin", outlined: true) {
                                    if viewModel.selectedLocation?.id == location.id { AppIcon("check") }
                                    else { AppIcon("caret-right") }
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(AppLayout.padding)
                }
            }
        }
        .background(AppColors.background)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}
