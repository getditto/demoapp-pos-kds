package live.ditto.pos.core.data.demo

// INITIAL lets peers seed the same defaults without overwriting existing edits.
// https://docs.ditto.live/dql/insert#insert-with-initial-documents

import com.ditto.kotlin.Ditto
import live.ditto.pos.core.data.SaleItemCommands
import live.ditto.pos.core.data.SaleItemCreation
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
            documents = LocationSeed.demoLocations.map { it.dittoJsonString() }
        )
    }

    suspend fun seedSaleItems() {
        bulkInitialInsert(
            collectionName = SaleItemCommands.CREATION_COLLECTION,
            documents = SaleItemSeed.saleItemsForAllLocations().map { SaleItemCreation(it.metadata, SaleItemSeed.INITIAL_QUANTITY).json() }
        )
        SeedStockMigration.upgradeAll(ditto.store)
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
