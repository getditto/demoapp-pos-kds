package live.ditto.pos.core.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SaleItem(
    @SerialName("_id") val documentId: DocumentID,
    val name: String,
    val imageName: String, // canonical wire key; resolve via ImageNameMapping
    val price: Money
) {
    val id: String get() = documentId.id
    val locationId: String get() = documentId.locationId

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
            price = Money(cents)
        )
    }
}
