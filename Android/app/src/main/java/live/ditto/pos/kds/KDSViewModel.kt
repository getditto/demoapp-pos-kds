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
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
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

    private val _uiState = MutableStateFlow(KdsUiState(tickets = emptyList()))
    val uiState: StateFlow<KdsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch(dispatcherIo) {
            getOrdersForTickets()
        }
    }

    fun updateTicketStatus(orderId: String) {
        viewModelScope.launch(dispatcherIo) {
            val orders = getOrdersForKdsUseCase().first()
            orders.firstOrNull { it.id == orderId }?.let { updateKDSOrderStatus(it) }
        }
    }

    private suspend fun getOrdersForTickets() {
        ordersJob = getOrdersForKdsUseCase()
            .onEach(::updateTickets)
            .flowOn(dispatcherIo)
            .launchIn(viewModelScope)
    }

    private fun updateTickets(orders: List<Order>) {
        val inProcess = orders.filter { it.status == OrderStatus.IN_PROCESS }
            .sortedByDescending { it.createdOn }
        val processed = orders.filter { it.status == OrderStatus.PROCESSED }
            .sortedByDescending { it.createdOn }

        _uiState.value = _uiState.value.copy(
            tickets = (inProcess + processed).map(::toTicketUi)
        )
    }

    private fun toTicketUi(order: Order): TicketItemUi = TicketItemUi(
        time = generateOrderTime(order.createdOn),
        shortOrderId = order.title,
        items = HashMap(order.summary),
        isPaid = order.isPaid,
        orderStatus = order.status,
        orderId = order.id
    )

    private fun generateOrderTime(inputDateTimeString: String): String {
        val inputFormat = SimpleDateFormat(INPUT_DATE_FORMAT, Locale.getDefault())
        val outputFormat = SimpleDateFormat(OUTPUT_DATE_FORMAT, Locale.getDefault())
        return runCatching {
            inputFormat.parse(inputDateTimeString)?.let { outputFormat.format(it) }
        }.getOrNull().orEmpty()
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
