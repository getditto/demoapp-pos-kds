package live.ditto.pos.pos.presentation.uimodel

import androidx.annotation.DrawableRes
import live.ditto.pos.core.data.ImageNameMapping
import live.ditto.pos.core.data.SaleItem

data class SaleItemUiModel(
    val id: String,
    @DrawableRes val imageResource: Int,
    val label: String,
    val price: Double = 0.0
) {
    companion object {
        fun from(saleItem: SaleItem): SaleItemUiModel = SaleItemUiModel(
            id = saleItem.id,
            imageResource = ImageNameMapping.resourceFor(saleItem.imageName) ?: 0,
            label = saleItem.name,
            price = saleItem.price.dollars
        )
    }
}
