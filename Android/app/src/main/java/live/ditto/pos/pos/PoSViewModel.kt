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

    // The order this view model is currently building. Set by
    // `ensureCurrentOrder` when entering a location, and by `payForOrder`
    // when opening the next order. The observer pipeline reads it to bind
    // the synced version of the same order.
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
        // The order pipeline has two phases per location entry:
        //   1. Resolve [currentOrderId] for the new location once.
        //   2. Bind the synced version of that fixed id on every emission.
        // Keeping creation out of the observer's map ensures Ditto observer
        // emissions only ever read the order — never write a new one.
        // flatMapLatest cancels the previous arm on location change so the UI
        // never mixes data from two locations.
        coreRepository.locationIdFlow()
            .filter { it.isNotEmpty() }
            .flatMapLatest { locationId ->
                ensureCurrentOrder(locationId)
                dittoRepository.observeLocationOrders(locationId).mapNotNull { orders ->
                    orders.firstOrNull { it.documentId.id == currentOrderId }
                }
            }
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

            // Open the next order for this location and point [currentOrderId]
            // at it. Creation lives here, not inside the observer pipeline.
            val next = Order.new(locationId = current.documentId.locationId)
            currentOrderId = next.documentId.id
            coreRepository.setCurrentOrderId(currentOrderId)
            dittoRepository.upsertOrder(next)
        }
    }

    fun clearItems() {
        val current = latestOrder ?: return
        viewModelScope.launch(dispatcherIO) {
            dittoRepository.clearCart(current)
        }
    }

    /**
     * Resolves [currentOrderId] for [locationId]. If the persisted id still
     * points at an open/in-process order at this location, we keep using it;
     * otherwise we create a fresh order. Called exactly once per location
     * entry so that the observer pipeline never has to create.
     */
    private suspend fun ensureCurrentOrder(locationId: String) {
        val savedId = coreRepository.currentOrderId()
        if (savedId.isNotEmpty()) {
            val snapshot = dittoRepository.observeLocationOrders(locationId).first()
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
        coreRepository.setCurrentOrderId(currentOrderId)
        dittoRepository.upsertOrder(order)
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
