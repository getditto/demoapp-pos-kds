package live.ditto.pos.pos

import android.icu.text.NumberFormat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.pos.domain.usecase.GetCurrentOpenOrderUseCase
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@HiltViewModel
class PoSViewModel @Inject constructor(
    getCurrentOpenOrderUseCase: GetCurrentOpenOrderUseCase,
    private val dispatcherIO: CoroutineDispatcher
) : ViewModel() {

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
            getCurrentOpenOrderUseCase()
                .onEach(::updateOrder)
                .flowOn(dispatcherIO)
                .collect()
        }
    }

    fun addItemToCart(saleItem: SaleItemUiModel) {
        val orderItem = OrderItemUiModel(
            name = saleItem.label,
            price = formatPrice(saleItem.price)
        )
        val orderItems = _uiState.value.orderItems.toMutableList().apply {
            add(orderItem)
        }
        _uiState.value = _uiState.value.copy(
            orderItems = orderItems
        )
    }

    private fun formatPrice(price: Float): String {
        return NumberFormat.getCurrencyInstance().format(price)
    }

    private fun updateOrder(order: Order) {
        val orderItems = createOrderItems(order)
        val orderTotal = calculateOrderTotal(orderItems)
        _uiState.value = _uiState.value.copy(
            currentOrderId = order.getOrderId(),
            orderItems = orderItems,
            orderTotal = orderTotal
        )
    }

    private fun calculateOrderTotal(orderItems: List<OrderItemUiModel>): String {
        var total = 0F
        orderItems.forEach {
            total += it.rawPrice
        }
        return formatPrice(total)
    }

    private fun createOrderItems(order: Order): List<OrderItemUiModel> {
        val saleItemIds = order.allSaleItemIds()
        return generateOrderItemUiModels(saleItemIds)
    }

    private fun generateOrderItemUiModels(saleItemIds: Collection<String>?): List<OrderItemUiModel> {
        return saleItemIds.let { ids ->
            ids?.map { id ->
                val saleItem = demoMenuData.find { it.id == id }
                OrderItemUiModel(
                    name = saleItem?.label ?: "",
                    price = formatPrice(saleItem?.price ?: 0F),
                    rawPrice = saleItem?.price ?: 0F
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
