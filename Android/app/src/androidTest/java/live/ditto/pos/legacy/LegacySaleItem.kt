// Frozen beab457 legacy seeding; wire payload and INITIAL statements retained.
package live.ditto.pos.legacy

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price

@Serializable
data class LegacySaleItem(
    @SerialName("_id") val documentId: DocumentID,
    val name: String,
    val imageName: String, // canonical wire key; resolve via ImageNameMapping
    val price: Price
) {
    companion object {
        const val COLLECTION_NAME = "sale_items"

        fun seed(
            id: String,
            locationId: String,
            name: String,
            imageName: String,
            cents: Int
        ): LegacySaleItem = LegacySaleItem(
            documentId = DocumentID(id = id, locationId = locationId),
            name = name,
            imageName = imageName,
            price = Price(cents)
        )
    }
}
