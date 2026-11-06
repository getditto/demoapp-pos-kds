package live.ditto.pos.pos

import android.icu.text.NumberFormat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.transform
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.PaymentType
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderSelection
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

    private val currentOrderId = MutableStateFlow("")

    private var activeLocation: String? = null

    private val currentOrder = appSettings.locationIdFlow()
        .flatMapLatest { locationId ->
            if (locationId.isEmpty()) return@flatMapLatest flowOf<Order?>(null)
            flow<Order?> {
                emit(null)
                if (activeLocation != locationId || currentOrderId.value.isEmpty()) ensureCurrentOrder(locationId)
                emitAll(
                    currentOrderId.flatMapLatest { id ->
                        ordersRepository.observeOrder(DocumentID(id, locationId)).transform { order ->
                            if (order == null) openNewOrder(locationId) else emit(order)
                        }
                    }
                )
            }
        }
        .onEach { latestOrder = it }
        .flowOn(dispatcherIO)

    private val catalog = appSettings.locationIdFlow()
        .flatMapLatest { locationId ->
            if (locationId.isEmpty()) return@flatMapLatest flowOf(locationId to emptyList<SaleItem>())
            saleItemsRepository.observeLocationSaleItems(locationId).map { locationId to it }
                .onStart { emit(locationId to emptyList()) }
        }
        .onEach { (locationId, items) ->
            latestCatalogLocation = locationId
            latestSaleItems = items
        }
        .flowOn(dispatcherIO)

    private var latestCatalogLocation: String? = null

    val uiState: StateFlow<PosUiState> = combine(currentOrder, catalog) { order, (locationId, items) ->
        if (order == null || order.documentId.locationId != locationId) {
            return@combine PosUiState("", emptyList(), "$0.00", emptyList())
        }
        PosUiState(
            currentOrderId = order.documentId.id,
            orderItems = order.sortedLineItems.map(OrderItemUiModel::from),
            orderTotal = NumberFormat.getCurrencyInstance().format(order.total.dollars),
            saleItems = items.map(SaleItemUiModel::from)
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(stopTimeoutMillis = 0, replayExpirationMillis = 0),
        PosUiState("", emptyList(), "$0.00", emptyList())
    )

    fun addItemToCart(saleItem: SaleItemUiModel) {
        val current = latestOrder ?: return
        if (current.documentId.locationId != latestCatalogLocation || saleItem.locationId != current.documentId.locationId) return
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
        if (current.documentId.locationId != latestCatalogLocation) return
        viewModelScope.launch(dispatcherIO) {
            val payment = Payment(type = PaymentType.CASH, amount = current.total)
            ordersRepository.upsert(current.addingPayment(payment, paymentId = Payment.newPaymentId()))

            // Repeated observer emissions must not create extra carts.
            openNewOrder(current.documentId.locationId)
        }
    }

    fun clearItems() {
        val current = latestOrder ?: return
        if (current.documentId.locationId != latestCatalogLocation) return
        viewModelScope.launch(dispatcherIO) {
            ordersRepository.clearCart(current)
        }
    }

    private suspend fun ensureCurrentOrder(locationId: String) {
        val savedId = appSettings.currentOrderId()
        if (savedId.isNotEmpty()) {
            val saved = ordersRepository.findRecentOrder(DocumentID(savedId, locationId))
            val reusableId = OrderSelection.reusableOrderId(savedId, listOfNotNull(saved))
            if (reusableId != null) {
                activeLocation = locationId
                currentOrderId.value = reusableId
                return
            }
        }
        openNewOrder(locationId)
    }

    private suspend fun openNewOrder(locationId: String) {
        val order = Order.new(locationId = locationId)
        ordersRepository.upsert(order)
        appSettings.setCurrentOrderId(order.documentId.id)
        activeLocation = locationId
        currentOrderId.value = order.documentId.id
    }
}

data class PosUiState(
    val currentOrderId: String,
    val orderItems: List<OrderItemUiModel>,
    val orderTotal: String,
    val saleItems: List<SaleItemUiModel>
)
