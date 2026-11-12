package live.ditto.pos.core.data

import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import live.ditto.pos.core.data.images.PhotoReference
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Instant

// Catalog edits must not rewrite the item details or prices recorded on an order.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class CartLineItem(
    val saleItemId: String,
    val name: String,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    val imageName: String? = null,
    val price: Price,
    val qty: Int = 1,
    @Serializable(with = DittoInstantSerializer::class)
    val createdAt: Instant = Clock.System.now(),
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    val image: PhotoReference? = null
) {
    companion object {
        fun newLineItemId(): String = UUID.randomUUID().toString()

        fun from(saleItem: SaleItem, qty: Int = 1): CartLineItem = CartLineItem(
            saleItemId = saleItem.documentId.id,
            name = saleItem.name,
            imageName = saleItem.imageName,
            price = saleItem.price,
            qty = qty,
            image = saleItem.image
        )
    }
}
