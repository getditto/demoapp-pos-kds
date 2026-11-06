package live.ditto.pos.core.data

import com.ditto.kotlin.DittoStore

object SaleItemCommands {
    // Stock deltas from different peers must compose.
    // https://docs.ditto.live/dql/types-and-definitions#counter-settable-counter
    const val CREATION_COLLECTION = "COLLECTION sale_items (quantity COUNTER)"

    suspend fun create(payload: SaleItemCreation, store: DittoStore) {
        require(payload.initialQuantity >= 0) { "Initial quantity cannot be negative" }
        store.execute(
            "INSERT INTO $CREATION_COLLECTION DOCUMENTS (deserialize_json(:json))",
            mapOf("json" to payload.json())
        )
    }

    suspend fun updateMetadata(metadata: SaleItemMetadata, store: DittoStore) {
        store.execute(
            """
                UPDATE sale_items SET name = :name, imageName = :imageName, price = deserialize_json(:price)
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf(
                "name" to metadata.name,
                "imageName" to metadata.imageName,
                "price" to metadata.price.dittoJsonString(),
                "id" to metadata.documentId.id,
                "locationId" to metadata.documentId.locationId
            )
        )
    }

    suspend fun increment(delta: Long, id: DocumentID, store: DittoStore) {
        counter("INCREMENT BY", delta, id, store)
    }

    suspend fun restart(quantity: Long, id: DocumentID, store: DittoStore) {
        require(quantity >= 0) { "Quantity cannot be negative" }
        counter("RESTART WITH", quantity, id, store)
    }

    private suspend fun counter(operation: String, value: Long, id: DocumentID, store: DittoStore) {
        store.execute(
            """
                UPDATE sale_items APPLY quantity $operation :value
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf("value" to value, "id" to id.id, "locationId" to id.locationId)
        )
    }
}
