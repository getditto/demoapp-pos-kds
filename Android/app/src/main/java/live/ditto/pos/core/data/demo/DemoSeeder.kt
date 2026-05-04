package live.ditto.pos.core.data.demo

// Demo-only orchestration. Seed content is in LocationSeed / SaleItemSeed.
//
// `INITIAL DOCUMENTS` writes each document only if it doesn't already exist
// — idempotent and peer-safe, so every device can run this on launch and
// the network converges on a single copy.

import live.ditto.Ditto
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.locations.Location

class DemoSeeder(private val ditto: Ditto) {

    suspend fun seedAll() {
        seedLocations()
        seedSaleItems()
    }

    suspend fun seedLocations() {
        bulkInitialInsert(
            collectionName = Location.COLLECTION_NAME,
            documents = LocationSeed.demoLocations.map { it.dittoJsonString() },
            label = "seedLocations"
        )
    }

    suspend fun seedSaleItems() {
        bulkInitialInsert(
            collectionName = SaleItem.COLLECTION_NAME,
            documents = SaleItemSeed.saleItemsForAllLocations().map { it.dittoJsonString() },
            label = "seedSaleItems"
        )
    }

    /**
     * Single bulk `INSERT INTO ... INITIAL DOCUMENTS (...), (...), ...`
     * — one round-trip for the whole seed set.
     */
    private suspend fun bulkInitialInsert(
        collectionName: String,
        documents: List<String>,
        label: String
    ) {
        if (documents.isEmpty()) return

        val args = mutableMapOf<String, Any>()
        val placeholders = documents.mapIndexed { index, json ->
            val key = "d$index"
            args[key] = json
            "(deserialize_json(:$key))"
        }

        try {
            ditto.store.execute(
                """
                INSERT INTO $collectionName
                INITIAL DOCUMENTS ${placeholders.joinToString(", ")}
                """.trimIndent(),
                args
            ).use { }
        } catch (error: Throwable) {
            android.util.Log.w("DemoSeeder", "$label: ${error.message}")
        }
    }
}
