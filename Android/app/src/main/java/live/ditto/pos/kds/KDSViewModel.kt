package live.ditto.pos.kds

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.data.orders.findOrderById
import live.ditto.pos.kds.domain.GetOrdersForKdsUseCase
import live.ditto.pos.kds.domain.UpdateKDSOrderStatus
import java.text.SimpleDateFormat
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class KDSViewModel @Inject constructor(
    private val getOrdersForKdsUseCase: GetOrdersForKdsUseCase,
    private val updateKDSOrderStatus: UpdateKDSOrderStatus,
    private val dispatcherIo: CoroutineDispatcher
) : ViewModel() {

    companion object {
        private const val INPUT_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        private const val OUTPUT_DATE_FORMAT = "h:mm a"
    }

    private var ordersJob: Job? = null

    private val _uiState = MutableStateFlow(
        KdsUiState(
            tickets = emptyList()
        )
    )
    val uiState: StateFlow<KdsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch(dispatcherIo) {
            getOrdersForTickets()
        }
    }

    fun updateTicketStatus(orderId: String) {
        viewModelScope.launch(dispatcherIo) {
            val orders = getOrdersForKdsUseCase().first()
            orders.findOrderById(id = orderId)
                .also {
                    updateOrderStatus(order = it)
                }
        }
    }

    private suspend fun updateOrderStatus(order: Order?) {
        order?.let {
            updateKDSOrderStatus(order = it)
        }
    }

    private suspend fun getOrdersForTickets() {
        ordersJob = getOrdersForKdsUseCase()
            .onEach(::updateTickets)
            .flowOn(dispatcherIo)
            .launchIn(viewModelScope)
    }

    private fun updateTickets(orders: List<Order>) {
        val inProcessOrders = orders.filter { it.status == OrderStatus.IN_PROCESS.ordinal }
            .sortedByDescending { it.createdOn }
        val processedOrders = orders.filter { it.status == OrderStatus.PROCESSED.ordinal }
            .sortedByDescending { it.createdOn }

        val inProcessTickets = inProcessOrders.map {
            createTicketItemUiFromOrder(it)
        }
        val processedTickets = processedOrders.map {
            createTicketItemUiFromOrder(it)
        }
        _uiState.value = _uiState.value.copy(
            tickets = inProcessTickets + processedTickets
        )
    }

    private fun createTicketItemUiFromOrder(order: Order): TicketItemUi {
        return TicketItemUi(
            time = generateOrderTime(inputDateTimeString = order.createdOn),
            shortOrderId = generateShortOrderId(orderId = order.getOrderId()),
            items = generateItems(order.sortedSaleItemIds()),
            isPaid = order.isPaid(),
            orderStatus = OrderStatus.entries[order.status],
            orderId = order.getOrderId()
        )
    }

    private fun generateShortOrderId(orderId: String): String {
        return orderId.substring(0, 8)
    }

    private fun generateOrderTime(inputDateTimeString: String): String {
        val inputFormat = SimpleDateFormat(INPUT_DATE_FORMAT, Locale.getDefault())
        val outputFormat = SimpleDateFormat(OUTPUT_DATE_FORMAT, Locale.getDefault())
        val inputDate = inputFormat.parse(inputDateTimeString)
        return inputDate?.let { outputFormat.format(it) } ?: ""
    }

    private fun generateItems(sortedSaleItemIds: Collection<String>?): HashMap<String, Int> {
        val items: HashMap<String, Int> = HashMap()
        sortedSaleItemIds?.mapNotNull { saleItemId ->
            demoMenuData.find { it.id == saleItemId }
        }?.forEach {
            val itemName = it.label

            val currentCount = items.getOrElse(
                itemName
            ) {
                0
            }
            items[itemName] = currentCount + 1
        }
        return items
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
