package live.ditto.pos.kds

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.datetime.Instant
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class KDSViewModel
@Inject
constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val dispatcherIo: CoroutineDispatcher
) : ViewModel() {

    companion object {
        private const val OUTPUT_DATE_FORMAT = "h:mm a"
    }

    private var ordersJob: Job? = null

    private val _uiState = MutableStateFlow(KdsUiState(tickets = emptyList()))
    val uiState: StateFlow<KdsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch(dispatcherIo) {
            ordersJob = activeKitchenOrders()
                .onEach(::updateTickets)
                .flowOn(dispatcherIo)
                .launchIn(viewModelScope)
        }
    }

    fun updateTicketStatus(orderId: String) {
        viewModelScope.launch(dispatcherIo) {
            val order = activeKitchenOrders().first().firstOrNull { it.id == orderId }
                ?: return@launch
            val nextStatus = when (order.status) {
                OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
                OrderStatus.PROCESSED -> OrderStatus.DELIVERED
                else -> return@launch
            }
            dittoRepository.upsertOrder(order.appendingStatus(nextStatus))

            if (nextStatus == OrderStatus.PROCESSED && coreRepository.currentOrderId() == order.id) {
                coreRepository.setCurrentOrderId("")
            }
        }
    }

    // Orders the kitchen cares about: in-process or processed, with items.
    private suspend fun activeKitchenOrders(): Flow<List<Order>> {
        val locationId = coreRepository.locationId()
        return dittoRepository.observeLocationOrders(locationId).map { orders ->
            orders.filter { order ->
                (order.status == OrderStatus.IN_PROCESS || order.status == OrderStatus.PROCESSED) &&
                    order.cart.isNotEmpty()
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
        orderId = order.id
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
