package live.ditto.pos.pos.presentation.uimodel

import androidx.annotation.DrawableRes

data class SaleItemUiModel(
    val id: String,
    @DrawableRes val imageResource: Int,
    val label: String,
    val price: Double = 0.0
)
