package live.ditto.pos.orders

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrdersHistory
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.settings.AppSettings
import live.ditto.ui.AppStatusTone
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class OrdersViewModel @Inject constructor(settings: AppSettings, repository: OrdersRepository) : ViewModel() {
    val history = OrdersHistory(viewModelScope, repository::observeHistoryPage, repository::observeHistoryCount)
    init {
        viewModelScope.launch { settings.locationIdFlow().collect { history.setLocation(it.takeIf(String::isNotEmpty)) } }
    }
}

internal class OrderHistoryRowViewModel(order: Order) {
    val title = "Order #${order.title}"
    val summary = order.summary.toSortedMap().entries.joinToString(" · ") { "${it.value} × ${it.key}" }
    val total = order.total.formatted()
    val date: String = DateTimeFormatter.ofPattern("MMM d, HH:mm", Locale.getDefault())
        .withZone(ZoneId.systemDefault()).format(java.time.Instant.ofEpochMilli(order.createdAt.toEpochMilliseconds()))
    private val statusPresentation = when (order.status) {
        OrderStatus.OPEN -> "Open" to AppStatusTone.SECONDARY
        OrderStatus.IN_PROCESS -> "Preparing" to AppStatusTone.ACTIVE
        OrderStatus.PROCESSED -> "Ready" to AppStatusTone.SUCCESS
        OrderStatus.DELIVERED -> "Delivered" to AppStatusTone.SUCCESS
        OrderStatus.CANCELED -> "Canceled" to AppStatusTone.SECONDARY
    }
    val status = statusPresentation.first
    val tone = statusPresentation.second
}
