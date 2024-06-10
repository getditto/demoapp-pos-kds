package live.ditto.pos.pos

import android.icu.text.NumberFormat
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

@HiltViewModel
class PoSViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(
        PosUiState(
            currentOrderId = "",
            orderItems = emptyList(),
            orderTotal = "$0.00"
        )
    )
    val uiState: StateFlow<PosUiState> = _uiState.asStateFlow()

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
}

data class PosUiState(
    val currentOrderId: String,
    val orderItems: List<OrderItemUiModel>,
    val orderTotal: String
)
