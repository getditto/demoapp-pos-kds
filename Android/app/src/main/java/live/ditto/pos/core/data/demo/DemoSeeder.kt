package live.ditto.pos.core.data.demo

// INITIAL lets peers seed the same defaults without overwriting existing edits.
// https://docs.ditto.live/dql/insert#insert-with-initial-documents

import com.ditto.kotlin.Ditto
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.locations.Location

class DemoSeeder(private val ditto: Ditto, private val photos: BundledFoodPhotos) {

    suspend fun seedAll() {
        seedLocations()
        seedSaleItems()
    }

    suspend fun seedLocations() {
        bulkInitialInsert(
            collectionName = Location.COLLECTION_NAME,
            documents = LocationSeed.demoLocations.map { it.dittoJsonString() }
        )
    }

    suspend fun seedSaleItems() {
        for (item in SaleItemSeed.saleItemsForAllLocations()) {
            val photo = photos.open(item.documentId.id).use { stream ->
                ditto.store.newAttachment(stream, mapOf("mime_type" to "image/png"))
            }
            photo.use {
                ditto.store.execute(
                    """
                        INSERT INTO COLLECTION ${SaleItem.COLLECTION_NAME} (quantity COUNTER, image ATTACHMENT)
                        INITIAL DOCUMENTS (:item)
                    """.trimIndent(),
                    mapOf(
                        "item" to mapOf(
                            "_id" to mapOf("id" to item.documentId.id, "locationId" to item.documentId.locationId),
                            "name" to item.name,
                            "price" to mapOf("amount" to item.price.amount, "currency" to "usd"),
                            "quantity" to item.quantity,
                            "image" to photo
                        )
                    )
                )
            }
        }
    }

    private suspend fun bulkInitialInsert(
        collectionName: String,
        documents: List<String>
    ) {
        if (documents.isEmpty()) return

        val args = mutableMapOf<String, Any>()
        val placeholders = documents.mapIndexed { index, json ->
            val key = "d$index"
            args[key] = json
            "(deserialize_json(:$key))"
        }

        ditto.store.execute(
            """
                INSERT INTO $collectionName
                INITIAL DOCUMENTS ${placeholders.joinToString(", ")}
            """.trimIndent(),
            args
        )
    }
}
