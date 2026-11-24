import AppUI
import Combine
import SwiftUI

struct InventoryView: View {
    @StateObject private var inventory: InventoryModel
    private let repository: SaleItemsRepository
    let isActive: Bool

    init(repository: SaleItemsRepository, locations: LocationsRepository, isActive: Bool) {
        self.repository = repository
        self.isActive = isActive
        _inventory = StateObject(wrappedValue: InventoryModel(repository: repository, locationPublisher: locations.$currentLocationId.eraseToAnyPublisher()))
    }
    var body: some View {
        InventoryContent(inventory: inventory) { item in
            ProductPhotoView(reference: item.image, owner: item.documentId, store: repository.store)
        }
        .onAppear { inventory.setVisible(isActive) }
        .onChange(of: isActive) { inventory.setVisible($0) }
        .onDisappear { inventory.setVisible(false) }
    }
}

struct InventoryContent<Photo: View>: View {
    @ObservedObject var inventory: InventoryModel
    let photo: (SaleItem) -> Photo
    @State private var focusedItem: DocumentID?
    @ScaledMetric(relativeTo: .body) private var digitWidth = InventoryRowViewModel.digitWidth

    var body: some View {
        Group {
            if inventory.state.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if inventory.state.items.isEmpty {
                AppEmptyState("No items yet", message: "Items for this location will appear here.", icon: "package", style: .large)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                            if inventory.state.edit == nil {
                                Text("\(inventory.state.items.count) items").font(AppTypography.footnote)
                                    .foregroundStyle(AppColors.secondaryText).padding(.bottom, AppLayout.smallGap)
                            }
                            ForEach(inventory.state.items, id: \.documentId) { item in
                                let row = InventoryRowViewModel(item: item, activeEdit: inventory.state.edit, scaledDigitWidth: digitWidth)
                                VStack(alignment: .leading, spacing: AppLayout.gap) {
                                    InventoryItemRow(viewModel: row, inventory: inventory, onFocus: { focusedItem = item.documentId }) { photo(item) }
                                    if let error = row.edit?.error {
                                        Text(error).font(AppTypography.caption).foregroundStyle(AppColors.critical)
                                            .accessibilityLabel("Error: \(error)")
                                    }
                                }.id(item.documentId)
                            }
                        }.padding(AppLayout.padding)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: focusedItem) { id in
                        if let id { withAnimation { proxy.scrollTo(id, anchor: .center) } }
                    }
                }
            }
        }
        .background(AppColors.background)
        .onChange(of: inventory.state.edit?.id) { id in if id == nil { focusedItem = nil } }
    }
}
