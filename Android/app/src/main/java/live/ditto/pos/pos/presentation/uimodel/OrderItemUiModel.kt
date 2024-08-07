package live.ditto.pos.pos.presentation.uimodel

data class OrderItemUiModel(
    val name: String,
    val price: String,
    val rawPrice: Float = 0F
)
