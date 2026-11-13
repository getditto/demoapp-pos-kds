package live.ditto.pos.pos.presentation.uimodel

import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.DocumentID

data class OrderItemUiModel(
    val name: String,
    val price: String,
    val rawPrice: Double = 0.0,
    val line: CartLineItem? = null,
    val orderId: DocumentID? = null
) {
    companion object {
        fun from(line: CartLineItem, orderId: DocumentID? = null): OrderItemUiModel = OrderItemUiModel(
            name = line.name,
            price = line.price.formatted(),
            rawPrice = line.price.dollars,
            line = line,
            orderId = orderId
        )
    }
}
