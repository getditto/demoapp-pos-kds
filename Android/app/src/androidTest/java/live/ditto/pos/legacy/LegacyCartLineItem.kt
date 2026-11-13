// Pinned beab457 serialization; only test package/type names differ.
package live.ditto.pos.legacy

import kotlinx.serialization.Serializable
import live.ditto.pos.core.data.DittoInstantSerializer
import live.ditto.pos.core.data.Price
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Instant

// Snapshot of a LegacySaleItem at add-time — the receipt records the price the
// customer paid, not the current LegacySaleItem price.
@Serializable
data class LegacyCartLineItem(
    val saleItemId: String,
    val name: String,
    val imageName: String,
    val price: Price,
    val qty: Int = 1,
    @Serializable(with = DittoInstantSerializer::class)
    val createdAt: Instant = Clock.System.now()
) {
    companion object {
        fun newLineItemId(): String = UUID.randomUUID().toString()

        fun from(saleItem: LegacySaleItem, qty: Int = 1): LegacyCartLineItem = LegacyCartLineItem(
            saleItemId = saleItem.documentId.id,
            name = saleItem.name,
            imageName = saleItem.imageName,
            price = saleItem.price,
            qty = qty
        )
    }
}
