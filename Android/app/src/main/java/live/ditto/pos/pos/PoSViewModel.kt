package live.ditto.pos.pos

import android.icu.text.NumberFormat
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
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.PaymentType
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class PoSViewModel
@Inject
constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val dispatcherIO: CoroutineDispatcher
) : ViewModel() {

    // Snapshots of the latest emissions, used by mutation handlers so they
    // don't have to re-collect the flows on every tap.
    private var latestOrder: Order? = null
    private var latestSaleItems: List<SaleItem> = emptyList()

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
        // Track the active location and re-create the orders + sale_items
        // observers when it changes. flatMapLatest cancels the previous
        // observer for us, so the UI never mixes data from two locations.
        coreRepository.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { locationId -> currentOrderFlow(locationId) }
            .onEach(::renderOrder)
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)

        coreRepository.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { dittoRepository.observeLocationSaleItems(it) }
            .onEach { items ->
                latestSaleItems = items
                _uiState.value = _uiState.value.copy(
                    saleItems = items.map(SaleItemUiModel::from)
                )
            }
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)
    }

    fun addItemToCart(saleItem: SaleItemUiModel) {
        val current = latestOrder ?: return
        val match = latestSaleItems.firstOrNull { it.documentId.id == saleItem.id } ?: return
        viewModelScope.launch(dispatcherIO) {
            val updated = current.addingCartLineItem(
                CartLineItem.from(match),
                lineItemId = CartLineItem.newLineItemId()
            )
            dittoRepository.upsertOrder(updated)
        }
    }

    fun payForOrder() {
        val current = latestOrder ?: return
        viewModelScope.launch(dispatcherIO) {
            val payment = Payment(type = PaymentType.CASH, amount = current.total)
            dittoRepository.upsertOrder(current.addingPayment(payment, paymentId = Payment.newPaymentId()))
            // Clear the saved id so currentOrderFlow creates a fresh order on
            // the next emission.
            coreRepository.setCurrentOrderId("")
        }
    }

    fun clearItems() {
        val current = latestOrder ?: return
        viewModelScope.launch(dispatcherIO) {
            dittoRepository.clearCart(current)
        }
    }

    /**
     * Resolves the order the POS is currently building for [locationId].
     * Reuses the saved `currentOrderId` if a matching open/in-process order
     * exists at this location; otherwise creates a fresh one.
     */
    private fun currentOrderFlow(locationId: String) =
        dittoRepository.observeLocationOrders(locationId).map { orders ->
            val savedOrderId = coreRepository.currentOrderId()
            orders.firstOrNull { it.documentId.id == savedOrderId }?.takeIf {
                it.status == OrderStatus.OPEN || it.status == OrderStatus.IN_PROCESS
            } ?: createNewOrder(locationId)
        }

    private suspend fun createNewOrder(locationId: String): Order {
        val order = Order.new(locationId = locationId)
        dittoRepository.upsertOrder(order)
        coreRepository.setCurrentOrderId(order.documentId.id)
        return order
    }

    private fun renderOrder(order: Order) {
        latestOrder = order
        _uiState.value = _uiState.value.copy(
            currentOrderId = order.documentId.id,
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
