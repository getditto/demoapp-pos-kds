package live.ditto.pos.core.data.demo

import com.ditto.kotlin.DittoAttachment
import com.ditto.kotlin.DittoStore
import com.ditto.kotlin.DittoTransaction
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.decodeOrSkip
import live.ditto.pos.core.data.dittoJson
import live.ditto.pos.core.data.images.PhotoAttachments
import live.ditto.pos.core.data.orders.dqlIdentifier

internal class SeedImageMigration(private val store: DittoStore, private val photos: BundledFoodPhotos) {
    suspend fun upgradeCatalog(locationId: String) {
        val rows = store.execute(
            "SELECT * FROM sale_items WHERE _id.locationId = :locationId AND imageName IS NOT MISSING",
            mapOf("locationId" to locationId)
        ) { it.decodeOrSkip<JsonObject>() }
        val candidates = rows.mapNotNull { row -> row.documentId()?.let { id -> Candidate(id, id, "imageName", "image") } }
        upgrade("sale_items", candidates)
    }

    suspend fun upgradeOrders(ids: List<DocumentID>) {
        val candidates = mutableListOf<Candidate>()
        for (id in ids.distinct()) {
            val rows = store.execute(
                "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
                mapOf("id" to id.id, "locationId" to id.locationId)
            ) { it.decodeOrSkip<JsonObject>() }
            for (row in rows) {
                val cart = row["cart"] as? JsonObject ?: continue
                for ((lineId, value) in cart) {
                    val line = value as? JsonObject ?: continue
                    if ("imageName" !in line) continue
                    val source = (line["saleItemId"] as? kotlinx.serialization.json.JsonPrimitive)?.takeIf { it.isString }?.contentOrNull
                    val path = "cart.${dqlIdentifier(lineId)}"
                    candidates += Candidate(id, source?.let { DocumentID(it, id.locationId) }, "$path.imageName", "$path.image", lineId)
                }
            }
        }
        upgrade("pos_orders", candidates)
    }

    suspend fun upgradeAll() {
        for (location in LocationSeed.demoLocations) {
            upgradeCatalog(location.id)
            val ids = store.execute(
                "SELECT _id FROM pos_orders WHERE _id.locationId = :locationId",
                mapOf("locationId" to location.id)
            ) { result -> result.decodeOrSkip<JsonObject>().mapNotNull { it.documentId() } }
            upgradeOrders(ids)
        }
    }

    private suspend fun upgrade(collection: String, candidates: List<Candidate>) {
        if (candidates.isEmpty()) return
        val attachments = mutableMapOf<DocumentID, DittoAttachment>()
        try {
            // Import before the transaction; only native attachment bindings enter DQL.
            // https://docs.ditto.live/sdk/latest/crud/working-with-attachments
            for (source in candidates.mapNotNull { it.source }.distinct()) {
                photos.bytes(source)?.let { attachments[source] = PhotoAttachments.importPhoto(it, "image/png", store) }
            }
            store.transaction { transaction ->
                for (candidate in candidates) {
                    val args = mutableMapOf<String, Any>("id" to candidate.owner.id, "locationId" to candidate.owner.locationId)
                    var guard = "_id.id = :id AND _id.locationId = :locationId AND ${candidate.legacyPath} IS NOT MISSING"
                    if (candidate.lineId != null && candidate.source != null) {
                        args["saleItemId"] = candidate.source.id
                        guard += " AND cart.${dqlIdentifier(candidate.lineId)}.saleItemId = :saleItemId"
                    }
                    attachments[candidate.source]?.let { attachment ->
                        val schema = candidate.lineId?.let { "cart MAP(${dqlIdentifier(it)} MAP(image ATTACHMENT))" } ?: "image ATTACHMENT"
                        transaction.execute(
                            "UPDATE COLLECTION $collection ($schema) SET ${candidate.imagePath} = :image WHERE $guard AND ${candidate.imagePath} IS MISSING",
                            args + ("image" to attachment)
                        )
                    }
                    transaction.execute("UPDATE $collection UNSET ${candidate.legacyPath} WHERE $guard", args)
                }
                DittoTransaction.Result.Commit()
            }
        } finally {
            attachments.values.forEach { it.close() }
        }
    }

    private data class Candidate(val owner: DocumentID, val source: DocumentID?, val legacyPath: String, val imagePath: String, val lineId: String? = null)
}

internal fun JsonObject.documentId(): DocumentID? = this["_id"]?.let {
    runCatching { dittoJson.decodeFromJsonElement<DocumentID>(it) }.getOrNull()
}

internal fun List<JsonObject>.hasLegacyCatalogInput(): Boolean = any { "imageName" in it }
internal fun List<JsonObject>.hasLegacyOrderInput(): Boolean = any { row ->
    (row["cart"] as? JsonObject)?.values?.any { it is JsonObject && "imageName" in it } == true
}
