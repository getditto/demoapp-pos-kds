package live.ditto.pos.kds

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.datetime.Instant
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.settings.AppSettings
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class KDSViewModel
@Inject
constructor(
    private val appSettings: AppSettings,
    private val ordersRepository: OrdersRepository,
    private val dispatcherIo: CoroutineDispatcher
) : ViewModel() {

    companion object {
        private const val OUTPUT_DATE_FORMAT = "h:mm a"
    }

    // Most-recent snapshot of the kitchen orders feed, used by the click
    // handler to find the order being advanced without re-collecting the flow.
    private var latestOrders: List<Order> = emptyList()

    private val _uiState = MutableStateFlow(KdsUiState(tickets = emptyList()))
    val uiState: StateFlow<KdsUiState> = _uiState.asStateFlow()

    init {
        // Re-observe whenever locationId changes — flatMapLatest cancels the
        // old observer and starts a fresh one for the new location.
        appSettings.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { locationId ->
                ordersRepository.observeLocationOrders(locationId).map { orders ->
                    orders.filter { order ->
                        (order.status == OrderStatus.IN_PROCESS || order.status == OrderStatus.PROCESSED) &&
                            order.cart.isNotEmpty()
                    }
                }
            }
            .onEach { orders ->
                latestOrders = orders
                updateTickets(orders)
            }
            .flowOn(dispatcherIo)
            .launchIn(viewModelScope)
    }

    fun updateTicketStatus(orderId: String) {
        viewModelScope.launch(dispatcherIo) {
            val order = latestOrders.firstOrNull { it.documentId.id == orderId } ?: return@launch
            val nextStatus = when (order.status) {
                OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
                OrderStatus.PROCESSED -> OrderStatus.DELIVERED
                else -> return@launch
            }
            ordersRepository.upsert(order.appendingStatus(nextStatus))

            if (nextStatus == OrderStatus.PROCESSED && appSettings.currentOrderId() == order.documentId.id) {
                appSettings.setCurrentOrderId("")
            }
        }
    }

    private fun updateTickets(orders: List<Order>) {
        val inProcess = orders.filter { it.status == OrderStatus.IN_PROCESS }
            .sortedByDescending { it.createdAt }
        val processed = orders.filter { it.status == OrderStatus.PROCESSED }
            .sortedByDescending { it.createdAt }

        _uiState.value = _uiState.value.copy(
            tickets = (inProcess + processed).map(::toTicketUi)
        )
    }

    private fun toTicketUi(order: Order): TicketItemUi = TicketItemUi(
        time = generateOrderTime(order.createdAt),
        shortOrderId = order.title,
        items = HashMap(order.summary),
        isPaid = order.isPaid,
        orderStatus = order.status,
        orderId = order.documentId.id
    )

    private fun generateOrderTime(instant: Instant): String {
        val outputFormat = SimpleDateFormat(OUTPUT_DATE_FORMAT, Locale.getDefault())
        return outputFormat.format(Date(instant.toEpochMilliseconds()))
    }
}

data class KdsUiState(
    val tickets: List<TicketItemUi>
)

data class TicketItemUi(
    val time: String,
    val shortOrderId: String,
    val items: HashMap<String, Int>,
    val isPaid: Boolean,
    val orderStatus: OrderStatus,
    val orderId: String
)
