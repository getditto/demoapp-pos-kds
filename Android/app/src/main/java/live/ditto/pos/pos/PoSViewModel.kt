package live.ditto.pos.pos

import android.icu.text.NumberFormat
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
import live.ditto.pos.pos.domain.usecase.AddSaleItemToOrderUseCase
import live.ditto.pos.pos.domain.usecase.CalculateOrderTotalUseCase
import live.ditto.pos.pos.domain.usecase.GetCurrentOrderUseCase
import live.ditto.pos.pos.domain.usecase.PayForOrderUseCase
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@HiltViewModel
class PoSViewModel @Inject constructor(
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase,
    private val addSaleItemToOrderUseCase: AddSaleItemToOrderUseCase,
    private val payForOrderUseCase: PayForOrderUseCase,
    private val calculateOrderTotalUseCase: CalculateOrderTotalUseCase,
    private val dispatcherIO: CoroutineDispatcher
) : ViewModel() {

    private var ordersJob: Job? = null

    private val _uiState = MutableStateFlow(
        PosUiState(
            currentOrderId = "",
            orderItems = emptyList(),
            orderTotal = "$0.00"
        )
    )
    val uiState: StateFlow<PosUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            updateCurrentOrder()
        }
    }

    fun addItemToCart(saleItem: SaleItemUiModel) {
        viewModelScope.launch(dispatcherIO) {
            addSaleItemToOrderUseCase(saleItemId = saleItem.id)
        }
    }

    fun payForOrder() {
        ordersJob?.cancel()
        viewModelScope.launch(dispatcherIO) {
            payForOrderUseCase()
            updateCurrentOrder()
        }
    }

    fun cancelOrder() {
        // todo
    }

    private suspend fun updateCurrentOrder() {
        ordersJob = getCurrentOrderUseCase()
            .onEach { updateAppState(it) }
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)
    }

    private fun updateAppState(order: Order) {
        val orderItems = createOrderItems(order)
        val orderTotal = formattedOrderTotal(order)
        _uiState.value = _uiState.value.copy(
            currentOrderId = order.getOrderId(),
            orderItems = orderItems,
            orderTotal = orderTotal
        )
    }

    private fun formattedOrderTotal(order: Order): String {
        val total = calculateOrderTotalUseCase(order = order)
        return formatPrice(total)
    }

    private fun formatPrice(price: Double): String {
        return NumberFormat.getCurrencyInstance().format(price)
    }

    private fun createOrderItems(order: Order): List<OrderItemUiModel> {
        val saleItemIds = order.sortedSaleItemIds()
        return generateOrderItemUiModels(saleItemIds)
    }

    private fun generateOrderItemUiModels(saleItemIds: Collection<String>?): List<OrderItemUiModel> {
        return saleItemIds.let { ids ->
            ids?.map { id ->
                val saleItem = demoMenuData.find { it.id == id }
                OrderItemUiModel(
                    name = saleItem?.label ?: "",
                    price = formatPrice(saleItem?.price ?: 0.0),
                    rawPrice = saleItem?.price ?: 0.0
                )
            }
        } ?: emptyList()
    }
}

data class PosUiState(
    val currentOrderId: String,
    val orderItems: List<OrderItemUiModel>,
    val orderTotal: String
)
