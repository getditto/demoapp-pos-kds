package live.ditto.pos.pos.presentation.uimodel

import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.images.PhotoReference

data class SaleItemUiModel(
    val id: String,
    val label: String,
    val price: Double = 0.0,
    val locationId: String = "",
    val image: PhotoReference? = null
) {
    companion object {
        fun from(saleItem: SaleItem): SaleItemUiModel = SaleItemUiModel(
            id = saleItem.documentId.id,
            label = saleItem.name,
            price = saleItem.price.dollars,
            locationId = saleItem.documentId.locationId,
            image = saleItem.image
        )
    }
}
