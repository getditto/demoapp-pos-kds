package live.ditto.pos.pos

import android.icu.text.NumberFormat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.core.data.findOrderById
import live.ditto.pos.pos.domain.usecase.GenerateOrderIdUseCase
import live.ditto.pos.pos.domain.usecase.GetOrdersForLocationUseCase
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@HiltViewModel
class PoSViewModel @Inject constructor(
    getOrdersForLocationUseCase: GetOrdersForLocationUseCase,
    dispatcherIO: CoroutineDispatcher,
    private val generateOrderIdUseCase: GenerateOrderIdUseCase
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
        getOrdersForLocationUseCase()
            .onEach(::updateOrderItems)
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)
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

    private fun updateOrderItems(orders: List<Order>) {
        val currentState = _uiState.value

        val updatedOrderId = generateOrderIdUseCase(currentOrderId = currentState.currentOrderId)
        val orderItems = createOrderItems(updatedOrderId, orders)
        val orderTotal = calculateOrderTotal(orderItems)
        _uiState.value = _uiState.value.copy(
            currentOrderId = updatedOrderId,
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

    private fun createOrderItems(orderId: String, orders: List<Order>): List<OrderItemUiModel> {
        // todo: filter by order status
        // from the filtered list get saleItemIds map where order id = orderId
        // convert saleItemIds to a list of OrderItemUIModel or return empty list
        val saleItemIds = orders
            .filter { it.status == OrderStatus.OPEN.ordinal }
            .findOrderById(orderId)
            ?.allSaleItemIds()
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
