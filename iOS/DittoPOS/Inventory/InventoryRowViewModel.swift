import AppUI
import SwiftUI

struct InventoryRowViewModel {
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

    init(item: SaleItem, activeEdit: QuantityEdit?) {
        edit = activeEdit?.id == item.documentId ? activeEdit : nil
        text = edit?.text ?? String(item.quantity)
        invalid = edit.map { $0.error != nil } ?? (item.quantity < 0)
        canDecrement = item.quantity > 0 && edit == nil
        canIncrement = edit == nil
        canEdit = activeEdit == nil
    }
}
