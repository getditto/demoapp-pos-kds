package live.ditto.pos.core.data.demo

import com.ditto.kotlin.DittoStore
import com.ditto.kotlin.DittoTransaction
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.decodeOrSkip

// INITIAL seeds leave existing documents unchanged, so legacy stock needs its own guarded update.
// https://docs.ditto.live/dql/types-and-definitions#creating-counters
object SeedStockMigration {
    private val seedIds = SaleItemSeed.saleItemsForAllLocations().map { it.documentId }.toSet()

    fun mayNeedUpgrade(items: List<SaleItem>): Boolean = items.any { it.quantity == null && it.documentId in seedIds }

    suspend fun upgrade(locationId: String, transaction: DittoTransaction) {
        val items = transaction.execute(
            "SELECT * FROM sale_items WHERE _id.locationId = :locationId AND quantity IS MISSING",
            mapOf("locationId" to locationId)
        ) { it.decodeOrSkip<SaleItem>() }
        for (item in items.filter { it.documentId in seedIds }) {
            transaction.execute(
                """
                    UPDATE sale_items APPLY quantity RESTART WITH :initialQuantity
                    WHERE _id.id = :id AND _id.locationId = :locationId AND quantity IS MISSING
                """.trimIndent(),
                mapOf("id" to item.documentId.id, "locationId" to locationId, "initialQuantity" to SaleItemSeed.INITIAL_QUANTITY)
            )
        }
    }

    suspend fun upgradeAll(store: DittoStore) {
        store.transaction { transaction ->
            for (location in LocationSeed.demoLocations) upgrade(location.id, transaction)
            DittoTransaction.Result.Commit(Unit)
        }
    }
}
