package live.ditto.pos.kds

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
            ordersRepository.observeLocationOrders(locationId).map { KitchenOrders.select(it) as List<Order>? }
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
            ordersRepository.upsert(order.appendingStatus(nextStatus))

            if (nextStatus == OrderStatus.PROCESSED && appSettings.currentOrderId() == order.documentId.id) {
                appSettings.setCurrentOrderId("")
            }
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
