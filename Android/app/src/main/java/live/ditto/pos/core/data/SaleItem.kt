package live.ditto.pos.core.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SaleItem(
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
        ): SaleItem = SaleItem(
            documentId = DocumentID(id = id, locationId = locationId),
            name = name,
            imageName = imageName,
            price = Price(cents)
        )
    }
}
