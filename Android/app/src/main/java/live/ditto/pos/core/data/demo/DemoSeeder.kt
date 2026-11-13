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
        bulkInitialInsert(
            collectionName = SaleItem.COLLECTION_NAME,
            documents = SaleItemSeed.initialDocuments()
        )
        SeedStockMigration.upgradeAll(ditto.store)
        SeedImageMigration(ditto.store, photos).upgradeAll()
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
