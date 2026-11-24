import AppUI
import SwiftUI

struct InventoryItemRow<Photo: View>: View {
    let viewModel: InventoryRowViewModel
    @ObservedObject var inventory: InventoryModel
    let onFocus: () -> Void
    let photo: Photo

    init(viewModel: InventoryRowViewModel, inventory: InventoryModel, onFocus: @escaping () -> Void, @ViewBuilder photo: () -> Photo) {
        self.viewModel = viewModel; self.inventory = inventory; self.onFocus = onFocus; self.photo = photo()
    }

    var body: some View {
        AppSurface(contentPadding: EdgeInsets(top: AppLayout.mediumGap, leading: AppLayout.gap, bottom: AppLayout.mediumGap, trailing: AppLayout.gap)) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppLayout.gap) { details; Spacer(minLength: AppLayout.gap); counter.fixedSize(horizontal: true, vertical: false) }
                VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                    details
                    HStack { Spacer(minLength: 0); counter }
                }
            }
        }
    }
    private var details: some View {
        HStack(spacing: AppLayout.gap) {
            photo.frame(width: AppLayout.thumbnailSize, height: AppLayout.thumbnailSize)
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Text(viewModel.name).font(AppTypography.body.weight(.medium))
                Text(viewModel.price).font(AppTypography.caption).foregroundStyle(AppColors.secondaryText)
            }.frame(minWidth: InventoryRowViewModel.minimumDetailsWidth, alignment: .leading)
        }
    }

    private var counter: some View {
        AppCounter(canDecrement: viewModel.canDecrement, canIncrement: viewModel.canIncrement,
                          decrement: { Task { try! await inventory.step(-1, id: viewModel.id) } },
                          increment: { Task { try! await inventory.step(1, id: viewModel.id) } }) {
            Group {
                if viewModel.editing {
                    AppNumberField(text: Binding(get: { inventory.state.edit?.text ?? "" }, set: { inventory.updateText($0) }),
                                   isValid: inventory.state.edit?.value != nil,
                                   onDone: { Task { try! await inventory.submit() } },
                                   onCancel: { inventory.cancelEditing() }, onFocus: onFocus)
                } else {
                    Button { inventory.beginEditing(viewModel.id) } label: {
                        Text(viewModel.text).lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, minHeight: AppLayout.controlHeight)
                    }.buttonStyle(.plain).disabled(!viewModel.canEdit)
                }
            }
            .font(AppTypography.quantity).multilineTextAlignment(.center)
            .foregroundStyle(viewModel.textColor)
            .frame(width: viewModel.quantityWidth)
            .frame(minHeight: AppLayout.controlHeight)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .overlay(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).strokeBorder(viewModel.borderColor, lineWidth: viewModel.borderWidth))
            .accessibilityLabel("\(viewModel.name) quantity")
            .accessibilityIdentifier("quantity-\(viewModel.id.id)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.name)
    }
}
