import AppUI
import SwiftUI

struct InventoryRowViewModel {
    let id: DocumentID
    let name: String
    let price: String
    let quantityWidth: CGFloat
    let edit: QuantityEdit?
    let text: String
    let invalid: Bool
    let canDecrement: Bool
    let canIncrement: Bool
    let canEdit: Bool
    var editing: Bool { edit != nil }
    var textColor: Color { invalid ? AppColors.critical : AppColors.text }
    var borderColor: Color { invalid ? AppColors.critical : editing ? AppColors.brandText : AppColors.border }
    var borderWidth: CGFloat { editing ? AppLayout.focusBorderWidth : AppLayout.borderWidth }

    init(item: SaleItem, activeEdit: QuantityEdit?, scaledDigitWidth: CGFloat = Self.digitWidth) {
        id = item.documentId
        name = item.name
        price = item.price.description
        edit = activeEdit?.id == item.documentId ? activeEdit : nil
        text = edit?.text ?? String(item.quantity)
        quantityWidth = min(Self.maximumQuantityWidth, max(AppLayout.controlHeight, CGFloat(text.count) * scaledDigitWidth + AppLayout.padding))
        invalid = edit.map { $0.error != nil } ?? (item.quantity < 0)
        canDecrement = item.quantity > 0 && edit == nil
        canIncrement = edit == nil
        canEdit = activeEdit == nil
    }
    static let digitWidth: CGFloat = 11
    static let minimumDetailsWidth: CGFloat = 72
    private static let maximumQuantityWidth: CGFloat = 144
}
