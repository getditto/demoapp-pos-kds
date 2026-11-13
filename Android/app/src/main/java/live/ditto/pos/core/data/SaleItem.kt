package live.ditto.pos.core.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonObject
import live.ditto.pos.core.data.images.PhotoReference

@Serializable
data class SaleItem(
    @SerialName("_id") val documentId: DocumentID,
    val name: String,
    val price: Price,
    val quantity: Long? = null,
    val image: PhotoReference? = null
) {
    val metadata: SaleItemMetadata get() = SaleItemMetadata(documentId, name, price)

    companion object {
        const val COLLECTION_NAME = "sale_items"

        fun seed(
            id: String,
            locationId: String,
            name: String,
            cents: Int
        ): SaleItem = SaleItem(
            documentId = DocumentID(id = id, locationId = locationId),
            name = name,
            price = Price(cents)
        )
    }
}

@Serializable
data class SaleItemMetadata(
    @SerialName("_id") val documentId: DocumentID,
    val name: String,
    val price: Price
)

data class SaleItemCreation(val metadata: SaleItemMetadata, val initialQuantity: Long) {
    fun json(): String = JsonObject(
        dittoJson.encodeToJsonElement(metadata).jsonObject + ("quantity" to JsonPrimitive(initialQuantity))
    ).toString()
}
