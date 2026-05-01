package live.ditto.pos.core.data

import kotlinx.serialization.Serializable
import java.util.UUID

// Snapshot of a SaleItem at add-time — the receipt records the price the
// customer paid, not the current SaleItem price.
@Serializable
data class CartLineItem(
    val saleItemId: String,
    val name: String,
    val imageName: String,
    val price: Money,
    val qty: Int = 1,
    val createdOn: String = isoNow()
) {
    companion object {
        fun newLineItemId(): String = UUID.randomUUID().toString()

        fun from(saleItem: SaleItem, qty: Int = 1): CartLineItem = CartLineItem(
            saleItemId = saleItem.id,
            name = saleItem.name,
            imageName = saleItem.imageName,
            price = saleItem.price,
            qty = qty
        )
    }
}
