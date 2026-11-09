package live.ditto.pos.pos.presentation.uimodel

import live.ditto.pos.core.data.CartLineItem

data class OrderItemUiModel(
    val name: String,
    val price: String,
    val rawPrice: Double = 0.0
) {
    companion object {
        fun from(line: CartLineItem): OrderItemUiModel = OrderItemUiModel(
            name = line.name,
            price = line.price.formatted(),
            rawPrice = line.price.dollars
        )
    }
}
