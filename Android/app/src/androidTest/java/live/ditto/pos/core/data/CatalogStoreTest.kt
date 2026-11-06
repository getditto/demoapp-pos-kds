package live.ditto.pos.core.data

import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.legacy.LegacyDemoSeeder
import live.ditto.pos.legacy.LegacySaleItemSeed
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CatalogStoreTest {
    @Test
    fun catalogCommandsPreserveStockAndMetadataByLocation() = runBlocking {
        TestDitto.withInstance {
            val repository = catalog()
            val id = DocumentID("coffee-'\"冰", "A")
            val other = id.copy(locationId = "B")
            val metadata = SaleItemMetadata(id, "Coffee", "coffee", Price(199))
            repository.create(SaleItemCreation(metadata, 2))
            repository.create(SaleItemCreation(metadata.copy(documentId = other, name = "Other", price = Price(250)), 7))
            repository.increment(-3, id)
            repository.updateMetadata(metadata.copy(name = "Renamed \"冰\"", imageName = "milk", price = Price(0)))
            val edited = readItem(id)
            assertEquals(-1L, edited.quantity)
            assertEquals("Renamed \"冰\"", edited.name)
            assertEquals(0, edited.price.amount)
            assertEquals(7L, readItem(other).quantity)
            assertEquals("Other", readItem(other).name)

            repository.restart(0, id)
            repository.increment(4, id)
            val replenished = readItem(id)
            assertEquals(4L, replenished.quantity)
            try {
                repository.restart(-1, id)
                fail("Negative absolute quantity was accepted")
            } catch (_: IllegalArgumentException) { }
            assertEquals(replenished, readItem(id))
        }
    }

    @Test
    fun exactOldAndNewInitialSeedersPreserveEditsVisibleDeletionAndFreeformItemsInEitherArrivalOrder() = runBlocking {
        for (oldFirst in listOf(true, false)) {
            TestDitto.withInstance {
                coroutineScope {
                    val repository = catalog()
                    val snapshots = Channel<List<SaleItem>>(Channel.UNLIMITED)
                    val observation = launch { repository.observeLocationSaleItems("00001").collect { snapshots.send(it) } }
                    try {
                        snapshots.await { it.isEmpty() }
                        val old = LegacyDemoSeeder(ditto)
                        val current = DemoSeeder(ditto)
                        if (oldFirst) old.seedAll()
                        current.seedAll()
                        old.seedAll()
                        val id = DocumentID("00001", "00001")
                        assertEquals(if (oldFirst) null else 20L, readItem(id).quantity)
                        val rows = ditto.store.execute("SELECT * FROM sale_items") { it.decode<SaleItem>() }
                        assertEquals(LegacySaleItemSeed.saleItemsForAllLocations().map { it.documentId }.toSet(), rows.map { it.documentId }.toSet())
                        val expectedIDs = LegacySaleItemSeed.saleItemsForAllLocations().filter { it.documentId.locationId == "00001" }.map { it.documentId }.toSet()
                        val visible = snapshots.await { it.map { item -> item.documentId }.toSet() == expectedIDs }
                        assertEquals(if (oldFirst) null else 20L, visible.single { it.documentId == id }.quantity)
                        repository.restart(0, id)
                        repository.increment(-2, id)
                        repository.updateMetadata(SaleItemMetadata(id, "Edited", "milk", Price(0)))
                        val removed = DocumentID("00008", "00001")
                        ditto.store.execute(
                            "DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
                            mapOf("id" to removed.id, "locationId" to removed.locationId)
                        )
                        val custom = SaleItemMetadata(DocumentID("95f203b6-0251-4ed8-8ae2-bbcb808bf356", "00001"), "Custom", "coffee", Price(0))
                        repository.create(SaleItemCreation(custom, 3))
                        current.seedAll()
                        old.seedAll()
                        current.seedAll()

                        val edited = readItem(id)
                        assertEquals(-2L, edited.quantity)
                        assertEquals("Edited", edited.name)
                        assertEquals(0, edited.price.amount)
                        assertEquals(custom, readItem(custom.documentId).metadata)
                        assertEquals(3L, readItem(custom.documentId).quantity)
                        val deletedVisibleItems = ditto.store.execute(
                            "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
                            mapOf("id" to removed.id, "locationId" to removed.locationId)
                        ) { it.decodeOrSkip<SaleItem>() }
                        assertTrue(deletedVisibleItems.isEmpty())
                        snapshots.await { items ->
                            items.none { it.documentId == removed } &&
                                items.any { it.documentId == custom.documentId && it.quantity == 3L } &&
                                items.any { it.documentId == id && it.name == "Edited" && it.quantity == -2L }
                        }
                    } finally {
                        observation.cancelAndJoin()
                        snapshots.close()
                    }
                }
            }
        }
    }

    private suspend fun <T> Channel<T>.await(predicate: (T) -> Boolean): T = withTimeout(5_000) {
        var value = receive()
        while (!predicate(value)) value = receive()
        value
    }

    private suspend fun TestDitto.readItem(id: DocumentID): SaleItem = ditto.store.execute(
        "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
        mapOf("id" to id.id, "locationId" to id.locationId)
    ) { it.decode<SaleItem>().single() }
}
