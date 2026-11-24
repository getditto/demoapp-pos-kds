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
    @ScaledMetric(relativeTo: .body) private var digitWidth = 11.0

    var body: some View {
        Group {
            if inventory.state.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if inventory.state.items.isEmpty {
                AppEmptyState("No items yet", message: "Items for this location will appear here.", icon: "package", style: .large)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if inventory.state.edit == nil {
                                Text("\(inventory.state.items.count) items").font(AppTypography.footnote)
                                    .foregroundStyle(AppColors.secondaryText).padding(.bottom, 4)
                            }
                            ForEach(inventory.state.items, id: \.documentId) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    AppCatalogRow(name: item.name, price: item.price.description) { photo(item) } controls: {
                                        counter(item)
                                    }
                                    if inventory.state.edit?.id == item.documentId, let error = inventory.state.edit?.error {
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

    private func counter(_ item: SaleItem) -> some View {
        let editing = inventory.state.edit?.id == item.documentId
        let text = editing ? inventory.state.edit!.text : String(item.quantity)
        let invalid = editing ? inventory.state.edit?.error != nil : item.quantity < 0
        return AppCounter(canDecrement: item.quantity > 0 && !editing, canIncrement: !editing,
                          decrement: { Task { try! await inventory.step(-1, id: item.documentId) } },
                          increment: { Task { try! await inventory.step(1, id: item.documentId) } }) {
            Group {
                if editing {
                    AppNumberField(text: Binding(get: { inventory.state.edit?.text ?? "" }, set: { inventory.updateText($0) }),
                                   isValid: inventory.state.edit?.value != nil,
                                   onDone: { Task { try! await inventory.submit() } },
                                   onCancel: { inventory.cancelEditing() }, onFocus: { focusedItem = item.documentId })
                } else {
                    Button { inventory.beginEditing(item.documentId) } label: {
                        Text(text).frame(maxWidth: .infinity, minHeight: AppLayout.controlHeight)
                    }.buttonStyle(.plain).disabled(inventory.state.edit != nil)
                }
            }
            .font(AppTypography.quantity).multilineTextAlignment(.center)
            .foregroundStyle(invalid ? AppColors.critical : AppColors.text)
            .frame(width: min(144, max(48, CGFloat(text.count) * digitWidth + 16)), height: AppLayout.controlHeight)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(invalid ? AppColors.critical : editing ? AppColors.brandText : AppColors.border, lineWidth: editing ? 2 : 1))
            .accessibilityLabel("\(item.name) quantity")
            .accessibilityIdentifier("quantity-\(item.documentId.id)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.name)
    }
}
