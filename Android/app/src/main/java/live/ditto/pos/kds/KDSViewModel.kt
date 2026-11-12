package live.ditto.pos.kds

import android.text.format.DateUtils
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.KitchenOrders
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.settings.AppSettings
import live.ditto.ui.AppColors
import live.ditto.ui.AppLayout
import live.ditto.ui.AppWindowLayout
import javax.inject.Inject
import kotlin.time.Instant

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class KDSViewModel
@Inject
constructor(
    private val appSettings: AppSettings,
    private val ordersRepository: OrdersRepository,
    private val dispatcherIo: CoroutineDispatcher
) : ViewModel() {

    private var latestOrders: List<Order> = emptyList()

    val uiState: StateFlow<KdsUiState> = appSettings.locationIdFlow()
        .flatMapLatest { locationId ->
            if (locationId.isEmpty()) return@flatMapLatest flowOf(emptyList<Order>())
            ordersRepository.observeKitchenOrders(locationId).map { it as List<Order>? }
                .onStart { emit(null) }
        }
        .onEach { orders ->
            latestOrders = orders.orEmpty()
        }
        .flowOn(dispatcherIo)
        .map { orders -> KdsUiState(tickets = orders.orEmpty().map(::toTicketUi), isLoading = orders == null) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(stopTimeoutMillis = 0, replayExpirationMillis = 0), KdsUiState(emptyList(), isLoading = true))

    fun updateTicketStatus(orderId: String) {
        viewModelScope.launch(dispatcherIo) {
            val order = latestOrders.firstOrNull { it.documentId.id == orderId } ?: return@launch
            val nextStatus = KitchenOrders.nextStatus(order.status) ?: return@launch
            ordersRepository.updateStatus(nextStatus, order.documentId)
        }
    }

    private fun toTicketUi(order: Order): TicketItemUi = TicketItemUi(
        createdAt = order.createdAt,
        shortOrderId = order.title,
        items = HashMap(order.summary),
        isPaid = order.isPaid,
        orderStatus = order.status,
        orderId = order.documentId.id
    )
}

data class KdsUiState(
    val tickets: List<TicketItemUi>,
    val isLoading: Boolean = false
)

data class TicketItemUi(
    val createdAt: Instant,
    val shortOrderId: String,
    val items: HashMap<String, Int>,
    val isPaid: Boolean,
    val orderStatus: OrderStatus,
    val orderId: String
)

class KitchenBoardViewModel(tickets: List<TicketItemUi>, availableWidth: Float) {
    val expanded = AppWindowLayout(availableWidth).expanded
    val preparing = tickets.filter { it.orderStatus == OrderStatus.IN_PROCESS }
    val ready = tickets.filter { it.orderStatus == OrderStatus.PROCESSED }
    val phoneTickets = preparing + ready
    val isEmpty = phoneTickets.isEmpty()
    val showPreparingWell = expanded && !isEmpty && preparing.isEmpty()
    val showReadyWell = expanded && !isEmpty && ready.isEmpty()
    val contentPadding = if (expanded) AppLayout.sectionGap else AppLayout.padding
    val headerSpacing = if (expanded) AppLayout.padding else AppLayout.mediumGap
    val headerStyle: TextStyle
        @Composable get() = if (expanded) MaterialTheme.typography.titleLarge else MaterialTheme.typography.bodyMedium

    fun countTitle(title: String, count: Int): String = if (expanded) "$title · $count" else "$title $count"
}

class KitchenTicketViewModel(ticket: TicketItemUi, now: Long) {
    val title = "#${ticket.shortOrderId}"
    val lines = ticket.items.toSortedMap().map { (name, count) -> "$count × $name" }
    val elapsed = DateUtils.getRelativeTimeSpanString(ticket.createdAt.toEpochMilliseconds(), now, DateUtils.MINUTE_IN_MILLIS, DateUtils.FORMAT_ABBREV_RELATIVE).toString()
    private val paid = ticket.isPaid
    private val ready = ticket.orderStatus == OrderStatus.PROCESSED
    val paymentTitle = if (paid) "Paid" else "Unpaid"
    val stageTitle = if (ready) "Ready" else "Preparing"
    val actionTitle = if (ready) "Complete order" else "Mark ready"
    val buttonTitle = actionTitle.uppercase()
    val actionLabel = "$actionTitle, $title"
    val secondaryAction = ready
    val paymentColor: Color
        @Composable get() = if (paid) AppColors.success else MaterialTheme.colorScheme.onSurfaceVariant
    val stageColor: Color
        @Composable get() = if (ready) AppColors.success else AppColors.brandText
}
