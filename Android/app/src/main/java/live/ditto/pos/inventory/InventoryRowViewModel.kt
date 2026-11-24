package live.ditto.pos.inventory

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import live.ditto.pos.core.data.SaleItem
import live.ditto.ui.AppLayout

internal class InventoryRowViewModel(item: SaleItem, activeEdit: QuantityEdit?, private val fontScale: Float = 1f) {
    val id = item.documentId
    val name = item.name
    val price = item.price.formatted()
    val edit = activeEdit?.takeIf { it.id == item.documentId }
    val text = edit?.text ?: item.quantity.toString()
    val quantityWidth = (text.length * DIGIT_WIDTH_DP * fontScale + AppLayout.padding.value)
        .coerceIn(AppLayout.controlHeight.value, MAXIMUM_QUANTITY_WIDTH_DP).dp
    fun stacksControls(availableWidth: Float) = availableWidth < MINIMUM_ROW_WIDTH_DP * fontScale
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
    private companion object {
        const val DIGIT_WIDTH_DP = 11f
        const val MAXIMUM_QUANTITY_WIDTH_DP = 144f
        const val MINIMUM_ROW_WIDTH_DP = 320f
    }
}
