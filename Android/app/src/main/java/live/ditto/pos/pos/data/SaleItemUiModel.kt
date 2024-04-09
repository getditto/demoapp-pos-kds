package live.ditto.pos.pos.data

import androidx.annotation.DrawableRes

data class SaleItemUiModel(
    @DrawableRes val imageResource: Int,
    val label: String,
    val price: Float = 0f
)
