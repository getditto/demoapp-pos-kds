package live.ditto.pos.pos.presentation.uimodel

import android.icu.text.NumberFormat
import live.ditto.pos.core.data.CartLineItem

data class OrderItemUiModel(
    val name: String,
    val price: String,
    val rawPrice: Double = 0.0
) {
    companion object {
        fun from(line: CartLineItem): OrderItemUiModel = OrderItemUiModel(
            name = line.name,
            price = NumberFormat.getCurrencyInstance().format(line.price.dollars),
            rawPrice = line.price.dollars
        )
    }
}
