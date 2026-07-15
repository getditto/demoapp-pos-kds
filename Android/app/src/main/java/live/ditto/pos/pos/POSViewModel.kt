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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.PaymentType
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.core.data.repository.SaleItemsRepository
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class POSViewModel
@Inject
constructor(
    private val appSettings: AppSettings,
    private val ordersRepository: OrdersRepository,
    private val saleItemsRepository: SaleItemsRepository,
    private val dispatcherIO: CoroutineDispatcher
) : ViewModel() {

    // Latest snapshots, so mutation handlers don't re-collect the flows.
    private var latestOrder: Order? = null
    private var latestSaleItems: List<SaleItem> = emptyList()

    // The order this view model is building. The observer pipeline reads it
    // to bind the synced version; only `ensureCurrentOrder` and
    // `payForOrder` write to it.
    private var currentOrderId: String = ""

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
        // Resolve the current order once per location, then just bind the
        // synced version on every emission. flatMapLatest cancels the
        // previous arm on location change.
        appSettings.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { locationId ->
                ensureCurrentOrder(locationId)
                ordersRepository.observeLocationOrders(locationId).mapNotNull { orders ->
                    orders.firstOrNull { it.documentId.id == currentOrderId }
                }
            }
            .onEach(::renderOrder)
            .flowOn(dispatcherIO)
            .launchIn(viewModelScope)

        appSettings.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { saleItemsRepository.observeLocationSaleItems(it) }
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
            ordersRepository.upsert(updated)
        }
    }

    fun payForOrder() {
        val current = latestOrder ?: return
        viewModelScope.launch(dispatcherIO) {
            val payment = Payment(type = PaymentType.CASH, amount = current.total)
            ordersRepository.upsert(current.addingPayment(payment, paymentId = Payment.newPaymentId()))

            // Open the next order explicitly; the observer never creates.
            val next = Order.new(locationId = current.documentId.locationId)
            currentOrderId = next.documentId.id
            appSettings.setCurrentOrderId(currentOrderId)
            ordersRepository.upsert(next)
        }
    }

    fun clearItems() {
        val current = latestOrder ?: return
        viewModelScope.launch(dispatcherIO) {
            ordersRepository.clearCart(current)
        }
    }

    /** Reuses the saved order if it's still open/in-process, otherwise creates a fresh one. */
    private suspend fun ensureCurrentOrder(locationId: String) {
        val savedId = appSettings.currentOrderId()
        if (savedId.isNotEmpty()) {
            val snapshot = ordersRepository.observeLocationOrders(locationId).first()
            val valid = snapshot.firstOrNull { it.documentId.id == savedId }?.let {
                it.status == OrderStatus.OPEN || it.status == OrderStatus.IN_PROCESS
            } == true
            if (valid) {
                currentOrderId = savedId
                return
            }
        }
        val order = Order.new(locationId = locationId)
        currentOrderId = order.documentId.id
        appSettings.setCurrentOrderId(currentOrderId)
        ordersRepository.upsert(order)
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
