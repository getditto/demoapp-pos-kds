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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.PaymentType
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@HiltViewModel
class PoSViewModel
@Inject
constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val dispatcherIO: CoroutineDispatcher
) : ViewModel() {

    private var ordersJob: Job? = null
    private var saleItemsJob: Job? = null

    private val _uiState = MutableStateFlow(
        PosUiState(
            currentOrderId = "",
            orderItems = emptyList(),
            orderTotal = "$0.00",
            saleItems = emptyList()
        )
    )
    val uiState: StateFlow<PosUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            observeCurrentOrder()
            observeSaleItems()
        }
    }

    fun addItemToCart(saleItem: SaleItemUiModel) {
        viewModelScope.launch(dispatcherIO) {
            val locationId = getCurrentLocationUseCase()?.id ?: return@launch
            val match = dittoRepository.observeLocationSaleItems(locationId).first()
                .firstOrNull { it.id == saleItem.id } ?: return@launch
            val current = currentOrderFlow().first()
            val updated = current.addingCartLineItem(
                CartLineItem.from(match),
                lineItemId = CartLineItem.newLineItemId()
            )
            dittoRepository.upsertOrder(updated)
        }
    }

    fun payForOrder() {
        ordersJob?.cancel()
        viewModelScope.launch(dispatcherIO) {
            val current = currentOrderFlow().first()
            val payment = Payment(type = PaymentType.CASH, amount = current.total)
            val paid = current.addingPayment(payment, paymentId = Payment.newPaymentId())
            dittoRepository.upsertOrder(paid)

            coreRepository.setCurrentOrderId("")
            createNewOrder()
            observeCurrentOrder()
        }
    }

    fun clearItems() {
        viewModelScope.launch(dispatcherIO) {
            dittoRepository.clearCart(currentOrderFlow().first())
        }
    }

    // Reuses the saved currentOrderId if a matching open/in-process order
    // exists at this location; otherwise creates a fresh order.
    private suspend fun currentOrderFlow() =
        dittoRepository.observeLocationOrders(activeLocationId()).map { orders ->
            val savedOrderId = coreRepository.currentOrderId()
            orders.firstOrNull { it.id == savedOrderId }?.takeIf {
                it.status == OrderStatus.OPEN || it.status == OrderStatus.IN_PROCESS
            } ?: createNewOrder()
        }

    private suspend fun createNewOrder(): Order {
        val order = Order.new(locationId = activeLocationId())
        dittoRepository.upsertOrder(order)
        coreRepository.setCurrentOrderId(order.id)
        return order
    }

    private suspend fun activeLocationId(): String =
        getCurrentLocationUseCase()?.id ?: ""

    private suspend fun observeCurrentOrder() {
        ordersJob = currentOrderFlow()
            .onEach(::renderOrder)
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)
    }

    private suspend fun observeSaleItems() {
        val locationId = getCurrentLocationUseCase()?.id ?: return
        saleItemsJob = dittoRepository.observeLocationSaleItems(locationId)
            .onEach { items ->
                _uiState.value = _uiState.value.copy(
                    saleItems = items.map(SaleItemUiModel::from)
                )
            }
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)
    }

    private fun renderOrder(order: Order) {
        _uiState.value = _uiState.value.copy(
            currentOrderId = order.id,
            orderItems = order.sortedLineItems.map(OrderItemUiModel::from),
            orderTotal = NumberFormat.getCurrencyInstance().format(order.total.dollars)
        )
    }
}

data class PosUiState(
    val currentOrderId: String,
    val orderItems: List<OrderItemUiModel>,
    val orderTotal: String,
    val saleItems: List<SaleItemUiModel>
)
