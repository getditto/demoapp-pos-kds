package live.ditto.pos.core.data.demo

// Demo-only orchestration. Seed content is in LocationSeed / SaleItemSeed.

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
        for (location in LocationSeed.demoLocations) {
            execute(
                query = """
                    INSERT INTO ${Location.COLLECTION_NAME}
                    INITIAL DOCUMENTS (deserialize_json(:json))
                """.trimIndent(),
                args = mapOf("json" to location.dittoJsonString()),
                label = "seedLocations"
            )
        }
    }

    suspend fun seedSaleItems() {
        for (item in SaleItemSeed.saleItemsForAllLocations()) {
            execute(
                query = """
                    INSERT INTO ${SaleItem.COLLECTION_NAME}
                    INITIAL DOCUMENTS (deserialize_json(:json))
                """.trimIndent(),
                args = mapOf("json" to item.dittoJsonString()),
                label = "seedSaleItems"
            )
        }
    }

    private suspend fun execute(query: String, args: Map<String, Any>, label: String) {
        try {
            ditto.store.execute(query, args).use { }
        } catch (error: Throwable) {
            android.util.Log.w("DemoSeeder", "$label: ${error.message}")
        }
    }
}
