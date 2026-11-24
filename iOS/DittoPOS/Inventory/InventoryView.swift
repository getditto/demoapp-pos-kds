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
    @ScaledMetric(relativeTo: .body) private var digitWidth = AppQuantityFieldViewModel.digitWidth

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
                                let row = InventoryRowViewModel(item: item, activeEdit: inventory.state.edit)
                                VStack(alignment: .leading, spacing: AppLayout.gap) {
                                    AppCatalogRow(name: item.name, price: item.price.description) { photo(item) } controls: {
                                        counter(item, row: row)
                                    }
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

    private func counter(_ item: SaleItem, row: InventoryRowViewModel) -> some View {
        return AppCounter(canDecrement: row.canDecrement, canIncrement: row.canIncrement,
                          decrement: { Task { try! await inventory.step(-1, id: item.documentId) } },
                          increment: { Task { try! await inventory.step(1, id: item.documentId) } }) {
            Group {
                if row.editing {
                    AppNumberField(text: Binding(get: { inventory.state.edit?.text ?? "" }, set: { inventory.updateText($0) }),
                                   isValid: inventory.state.edit?.value != nil,
                                   onDone: { Task { try! await inventory.submit() } },
                                   onCancel: { inventory.cancelEditing() }, onFocus: { focusedItem = item.documentId })
                } else {
                    Button { inventory.beginEditing(item.documentId) } label: {
                        Text(row.text).frame(maxWidth: .infinity, minHeight: AppLayout.controlHeight)
                    }.buttonStyle(.plain).disabled(!row.canEdit)
                }
            }
            .font(AppTypography.quantity).multilineTextAlignment(.center)
            .foregroundStyle(row.textColor)
            .frame(width: AppQuantityFieldViewModel(text: row.text, scaledDigitWidth: digitWidth).width, height: AppLayout.controlHeight)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .overlay(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).strokeBorder(row.borderColor, lineWidth: row.borderWidth))
            .accessibilityLabel("\(item.name) quantity")
            .accessibilityIdentifier("quantity-\(item.documentId.id)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.name)
    }
}
