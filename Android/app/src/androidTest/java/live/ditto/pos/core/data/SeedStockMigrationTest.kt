package live.ditto.pos.core.data

import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.core.data.demo.SeedStockMigration
import live.ditto.pos.legacy.LegacyDemoSeeder
import live.ditto.pos.legacy.LegacySaleItem
import live.ditto.pos.legacy.LegacySaleItemSeed
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SeedStockMigrationTest {
    @Test
    fun startupUpgradesLegacyMenusWithoutResettingEditsStockOrUnrelatedItems() = runBlocking {
        TestDitto.withInstance {
            LegacyDemoSeeder(ditto).seedAll()
            val catalog = catalog()
            val expected = LegacySaleItemSeed.saleItemsForAllLocations().associate {
                it.documentId to SaleItemMetadata(it.documentId, it.name, it.imageName, it.price)
            }.toMutableMap()
            for (location in LocationSeed.demoLocations) {
                val id = LegacySaleItemSeed.saleItemsForAllLocations().first { it.documentId.locationId == location.id }.documentId
                val edited = SaleItemMetadata(id, "Edited \"${location.id}\"", "milk", Price(0))
                catalog.updateMetadata(edited)
                expected[id] = edited
            }
            val positive = DocumentID("00001", "00001")
            val zero = DocumentID("00008", "00001")
            val negative = DocumentID("00013", "00001")
            val stock = mapOf(positive to 7L, zero to 0L, negative to -2L)
            for ((id, value) in stock) {
                if (value < 0) {
                    catalog.restart(0, id)
                    catalog.increment(value, id)
                } else {
                    catalog.restart(value, id)
                }
            }
            val deleted = DocumentID("00018", "00001")
            val partial = DocumentID("00012", "00001")
            ditto.store.execute("DELETE FROM sale_items WHERE _id = :id", mapOf("id" to mapOf("id" to deleted.id, "locationId" to deleted.locationId)))
            ditto.store.execute("UPDATE sale_items UNSET price WHERE _id = :id", mapOf("id" to mapOf("id" to partial.id, "locationId" to partial.locationId)))
            expected.remove(deleted)
            expected.remove(partial)
            for (id in listOf(DocumentID("f23b0e5a-f372-4578-a4f9-efc8323a4bd7", "00001"), DocumentID("00001", "00002"))) {
                val item = LegacySaleItem.seed(id.id, id.locationId, "Custom", "coffee", 0)
                ditto.store.execute("INSERT INTO sale_items DOCUMENTS (deserialize_json(:json))", mapOf("json" to item.dittoJsonString()))
                expected[id] = SaleItemMetadata(id, item.name, item.imageName, item.price)
            }
            DemoSeeder(ditto).seedAll()
            val upgraded = allItems()
            assertEquals(expected, upgraded.associate { it.documentId to it.metadata })
            val seedIds = LegacySaleItemSeed.saleItemsForAllLocations().map { it.documentId }.toSet()
            for (item in upgraded) {
                assertEquals(item.documentId.toString(), if (item.documentId in seedIds) stock[item.documentId] ?: 20L else null, item.quantity)
            }
            val absent = ditto.store.execute(
                "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId AND quantity IS MISSING",
                mapOf("id" to partial.id, "locationId" to partial.locationId)
            ) { it.items.size }
            assertEquals(1, absent)
            catalog.increment(-1, positive)
            val beforeRetry = allItems()
            DemoSeeder(ditto).seedAll()
            assertEquals(beforeRetry.toSet(), allItems().toSet())
        }
    }

    @Test
    fun migrationUsesTheCallerTransactionAndCanRetryAfterAnInterruptedUpgrade() = runBlocking {
        class Interrupted : RuntimeException()
        TestDitto.withInstance {
            LegacyDemoSeeder(ditto).seedAll()
            val before = allItems()
            try {
                ditto.store.transaction<Unit> { transaction ->
                    SeedStockMigration.upgrade("00001", transaction)
                    throw Interrupted()
                }
                fail("Expected interrupted upgrade")
            } catch (_: Interrupted) { }
            assertEquals(before.toSet(), allItems().toSet())
            val id = DocumentID("00001", "00001")
            SaleItemCommands.restart(0, id, ditto.store)
            SeedStockMigration.upgradeAll(ditto.store)
            val retried = allItems()
            assertEquals(before.size, retried.size)
            for (item in retried) assertEquals(if (item.documentId == id) 0L else 20L, item.quantity)
        }
    }

    @Test
    fun visibleCatalogUpgradesLateLegacyInputAndLocationReentryPreservesStock() = runBlocking {
        TestDitto.withInstance {
            val catalog = catalog()
            val snapshots = Channel<List<SaleItem>>(Channel.UNLIMITED)
            coroutineScope {
                var observation = launch { catalog.observeLocationSaleItems("00001").collect { snapshots.send(it) } }
                try {
                    snapshots.await { it.isEmpty() }
                    LegacyDemoSeeder(ditto).seedAll()
                    val prepared = snapshots.await { it.size == 7 }
                    assertTrue(prepared.all { it.quantity == 20L })
                    observation.cancelAndJoin()
                    assertTrue(ditto.store.observers.isEmpty())
                    while (snapshots.tryReceive().isSuccess) { }
                    observation = launch { catalog.observeLocationSaleItems("00002").collect { snapshots.send(it) } }
                    val other = snapshots.await { it.size == 7 }
                    assertTrue(other.all { it.quantity == 20L })
                    observation.cancelAndJoin()
                    val id = DocumentID("00001", "00001")
                    catalog.restart(0, id)
                    catalog.increment(-2, id)
                    while (snapshots.tryReceive().isSuccess) { }
                    observation = launch { catalog.observeLocationSaleItems("00001").collect { snapshots.send(it) } }
                    val returned = snapshots.await { it.size == 7 }
                    assertEquals(-2L, returned.single { it.documentId == id }.quantity)
                } finally {
                    observation.cancelAndJoin()
                    snapshots.close()
                }
            }
        }
    }

    private suspend fun TestDitto.allItems(): List<SaleItem> = ditto.store.execute("SELECT * FROM sale_items") { it.decodeOrSkip<SaleItem>() }

    private suspend fun Channel<List<SaleItem>>.await(predicate: (List<SaleItem>) -> Boolean): List<SaleItem> = withTimeout(5_000) {
        var value = receive()
        while (!predicate(value)) value = receive()
        value
    }
}
