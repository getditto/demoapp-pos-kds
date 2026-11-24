package live.ditto.pos.orders

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.ui.AppColors
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

internal class OrderSummaryViewModel(order: Order, availableWidth: Float, fontScale: Float) {
    val usesColumns = availableWidth >= OrderSummaryLayout.MINIMUM_TABLE_WIDTH && fontScale < OrderSummaryLayout.LARGE_FONT_SCALE
    private val orderStatus = order.status
    val title = "Order #${order.title}"
    val summary = order.summary.toSortedMap().entries.joinToString(" · ") { "${it.value} × ${it.key}" }
    val total = order.total.formatted()
    val date: String = DateTimeFormatter.ofPattern("MMM d, HH:mm", Locale.getDefault())
        .withZone(ZoneId.systemDefault()).format(java.time.Instant.ofEpochMilli(order.createdAt.toEpochMilliseconds()))
    val status = when (orderStatus) {
        OrderStatus.OPEN -> "Open"
        OrderStatus.IN_PROCESS -> "Preparing"
        OrderStatus.PROCESSED -> "Ready"
        OrderStatus.DELIVERED -> "Delivered"
        OrderStatus.CANCELED -> "Canceled"
    }
    val statusColor: Color
        @Composable get() = when (orderStatus) {
            OrderStatus.IN_PROCESS -> AppColors.brandText
            OrderStatus.PROCESSED, OrderStatus.DELIVERED -> AppColors.success
            else -> MaterialTheme.colorScheme.onSurfaceVariant
        }
}

internal object OrderSummaryLayout {
    const val LARGE_FONT_SCALE = 1.5f
    const val MINIMUM_TABLE_WIDTH = 760f
    val titleWidth = 168.dp
    val statusWidth = 100.dp
    val dateWidth = 150.dp
    val totalWidth = 80.dp
}
