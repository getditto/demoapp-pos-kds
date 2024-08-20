package live.ditto.pos.kds

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.data.transactions.TransactionStatus
import live.ditto.pos.kds.domain.GetOrdersForKdsUseCase
import javax.inject.Inject

@HiltViewModel
class KDSViewModel @Inject constructor(
    private val getOrdersForKdsUseCase: GetOrdersForKdsUseCase,
    private val dispatcherIo: CoroutineDispatcher
) : ViewModel() {

    private var ordersJob: Job? = null

    private val _uiState = MutableStateFlow(
        KdsUiState(
            tickets = emptyList()
        )
    )
    val uiState: StateFlow<KdsUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            getOrdersForTickets()
        }
    }

    private suspend fun getOrdersForTickets() {
        ordersJob = getOrdersForKdsUseCase()
            .onEach(::updateTickets)
            .flowOn(dispatcherIo)
            .launchIn(viewModelScope)
    }

    private fun updateTickets(orders: List<Order>) {
        val ticketItems = orders.map {
            TicketItemUi(
                header = it.getOrderId().substring(0, 8),
                items = generateItems(it.sortedSaleItemIds()),
                isPaid = generatePaidStatus(it),
                orderStatus = OrderStatus.entries[it.status]
            )
        }
        _uiState.value = _uiState.value.copy(
            tickets = ticketItems
        )
    }

    private fun generatePaidStatus(order: Order): Boolean {
        return order.transactionIds.values.contains(TransactionStatus.COMPLETE.ordinal)
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
    val header: String,
    val items: HashMap<String, Int>,
    val isPaid: Boolean,
    val orderStatus: OrderStatus
)
