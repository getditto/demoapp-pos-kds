// Freeze beab457 payloads/INITIAL writes so migration tests cannot track new model changes.
package live.ditto.pos.legacy

import com.ditto.kotlin.Ditto
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.legacy.LegacySaleItem

class LegacyDemoSeeder(private val ditto: Ditto) {

    suspend fun seedAll() {
        seedLocations()
        seedSaleItems()
    }

    suspend fun seedLocations() {
        bulkInitialInsert(
            collectionName = Location.COLLECTION_NAME,
            documents = LegacyLocationSeed.demoLocations.map { it.dittoJsonString() },
            label = "seedLocations"
        )
    }

    suspend fun seedSaleItems() {
        bulkInitialInsert(
            collectionName = LegacySaleItem.COLLECTION_NAME,
            documents = LegacySaleItemSeed.saleItemsForAllLocations().map { it.dittoJsonString() },
            label = "seedSaleItems"
        )
    }

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
            )
        } catch (error: Throwable) {
            android.util.Log.w("LegacyDemoSeeder", "$label: ${error.message}")
        }
    }
}
