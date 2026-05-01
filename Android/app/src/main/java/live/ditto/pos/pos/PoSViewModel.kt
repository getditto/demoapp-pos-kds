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
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.pos.domain.usecase.AddSaleItemToOrderUseCase
import live.ditto.pos.pos.domain.usecase.CalculateOrderTotalUseCase
import live.ditto.pos.pos.domain.usecase.ClearCurrentOrderSaleItemsUseCase
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
    private val clearCurrentOrderSaleItemsUseCase: ClearCurrentOrderSaleItemsUseCase,
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
            updateCurrentOrder()
            observeSaleItems()
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

    fun clearItems() {
        viewModelScope.launch(dispatcherIO) {
            clearCurrentOrderSaleItemsUseCase()
        }
    }

    private suspend fun updateCurrentOrder() {
        ordersJob = getCurrentOrderUseCase()
            .onEach { updateAppState(it) }
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

    private fun updateAppState(order: Order) {
        _uiState.value = _uiState.value.copy(
            currentOrderId = order.id,
            orderItems = order.sortedLineItems.map(OrderItemUiModel::from),
            orderTotal = formatPrice(calculateOrderTotalUseCase(order))
        )
    }

    private fun formatPrice(price: Double): String =
        NumberFormat.getCurrencyInstance().format(price)
}

data class PosUiState(
    val currentOrderId: String,
    val orderItems: List<OrderItemUiModel>,
    val orderTotal: String,
    val saleItems: List<SaleItemUiModel>
)
