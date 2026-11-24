package live.ditto.pos.inventory

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import live.ditto.pos.core.data.SaleItem
import live.ditto.ui.AppLayout

internal class InventoryRowViewModel(item: SaleItem, activeEdit: QuantityEdit?) {
    val edit = activeEdit?.takeIf { it.id == item.documentId }
    val text = edit?.text ?: item.quantity.toString()
    val invalid = edit?.let { it.error != null } ?: (item.quantity < 0)
    val canDecrement = item.quantity > 0 && edit == null
    val canIncrement = edit == null
    val canEdit = activeEdit == null
    val borderWidth = if (edit == null) AppLayout.borderWidth else AppLayout.focusBorderWidth
    val textColor: Color
        @Composable get() = if (invalid) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
    val borderColor: Color
        @Composable get() = when {
            invalid -> MaterialTheme.colorScheme.error
            edit != null -> MaterialTheme.colorScheme.primary
            else -> MaterialTheme.colorScheme.outlineVariant
        }
}
