package live.ditto.pos.core.data

import android.graphics.Color
import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.demo.SaleItemSeed
import live.ditto.pos.core.data.images.PhotoAttachments
import live.ditto.pos.core.data.images.PhotoTestImages
import live.ditto.pos.core.data.orders.Order
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
            val id = DocumentID("coffee-'\"iced", "A")
            val other = id.copy(locationId = "B")
            val metadata = SaleItemMetadata(id, "Coffee", Price(199))
            repository.create(SaleItemCreation(metadata, 2))
            repository.create(SaleItemCreation(metadata.copy(documentId = other, name = "Other", price = Price(250)), 7))
            repository.increment(-3, id)
            val replacement = metadata.copy(name = "Renamed \"iced\"", price = Price(0))
            repository.updateMetadata(replacement)
            val edited = readItem(id)
            assertEquals(-1L, edited.quantity)
            assertEquals(replacement, edited.metadata)
            assertEquals(7L, readItem(other).quantity)
            assertEquals("Other", readItem(other).name)

            repository.restart(0, id)
            repository.increment(4, id)
            val replenished = readItem(id)
            assertEquals(4L, replenished.quantity)
            assertEquals(replacement, replenished.metadata)
            try {
                repository.restart(-1, id)
                fail("Negative absolute quantity was accepted")
            } catch (_: IllegalArgumentException) { }
            assertEquals(replenished, readItem(id))
        }
    }

    @Test
    fun starterAttachmentsAndReseedingPreserveCatalogChanges() = runBlocking {
        TestDitto.withInstance {
            val repository = catalog()
            val seeder = DemoSeeder(ditto, bundledPhotos)
            seeder.seedAll()
            val seeded = ditto.store.execute("SELECT * FROM sale_items_v2") { it.decode<SaleItem>() }
            assertEquals(SaleItemSeed.saleItemsForAllLocations().map { it.metadata }.toSet(), seeded.map { it.metadata }.toSet())
            for (item in seeded) {
                assertEquals(20L, item.quantity)
                PhotoAttachments.importPhoto(bundledPhotos.bytes(item.documentId.id), "image/png", ditto.store).use { photo ->
                    assertEquals(PhotoAttachments.reference(photo), item.image)
                }
            }

            val editedId = DocumentID("00001", "00001")
            val noPhotoId = DocumentID("00013", "00001")
            val deletedId = DocumentID("00008", "00001")
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { changedPhoto ->
                repository.increment(-22, editedId)
                repository.updateMetadata(SaleItemMetadata(editedId, "Edited", Price(0)))
                PhotoAttachments.replace(changedPhoto, editedId, ditto.store)
                repository.restart(0, noPhotoId)
                PhotoAttachments.remove(noPhotoId, ditto.store)
                ditto.store.execute(
                    "DELETE FROM sale_items_v2 WHERE _id.id = :id AND _id.locationId = :locationId",
                    mapOf("id" to deletedId.id, "locationId" to deletedId.locationId)
                )
                val custom = SaleItemMetadata(DocumentID("custom", "00001"), "Custom", Price(0))
                repository.create(SaleItemCreation(custom, 3))
                coroutineScope {
                    val observedItems = Channel<List<SaleItem>>(Channel.UNLIMITED)
                    val observation = launch { repository.observeLocationSaleItems("00001").collect { observedItems.send(it) } }
                    try {
                        seeder.seedAll()
                        seeder.seedAll()
                        val edited = readItem(editedId)
                        assertEquals(-2L, edited.quantity)
                        assertEquals("Edited", edited.name)
                        assertEquals(0, edited.price.amount)
                        assertEquals(PhotoAttachments.reference(changedPhoto), edited.image)
                        val noPhoto = readItem(noPhotoId)
                        assertEquals(0L, noPhoto.quantity)
                        assertNull(noPhoto.image)
                        val retainedCustom = readItem(custom.documentId)
                        assertEquals(custom, retainedCustom.metadata)
                        assertEquals(3L, retainedCustom.quantity)
                        assertNull(retainedCustom.image)
                        val visible = observedItems.await { items ->
                            items.none { it.documentId == deletedId } && items.any { it.documentId == custom.documentId }
                        }
                        assertEquals(7, visible.size)
                        assertTrue(visible.all { it.documentId.locationId == "00001" })
                    } finally {
                        observation.cancelAndJoin()
                        observedItems.close()
                    }
                }
            }
        }
    }

    @Test
    fun cutoverIgnoresOldCollectionsAndLeavesTheirDocumentsUntouched() = runBlocking {
        TestDitto.withInstance {
            val order = TestDitto.fixture()
            ditto.store.execute("INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json))", mapOf("json" to order.dittoJsonString()))
            ditto.store.execute(
                """
                    INSERT INTO sale_items DOCUMENTS ({"_id": {"id": "00001", "locationId": "00001"}, "name": "Old item", "quantity": 99})
                """.trimIndent()
            )
            DemoSeeder(ditto, bundledPhotos).seedAll()
            val catalog = catalog()
            val items = withTimeout(5_000) { catalog.observeLocationSaleItems("00001").first() }
            assertEquals("Burger", items.single { it.documentId.id == "00001" }.name)
            val orders = repository()
            assertNull(orders.findOrder(order.documentId))
            assertNull(withTimeout(5_000) { orders.observeOrder(order.documentId).first() })
            orders.upsert(order)
            val current = ditto.store.execute("SELECT * FROM pos_orders_v2") { it.decode<Order>() }
            assertEquals(listOf(order), current)
            catalog.increment(-1, DocumentID("00001", "00001"))
            ditto.store.execute("SELECT name, quantity FROM sale_items") {
                val oldItem = dittoJson.parseToJsonElement(it.items.single().jsonString()).jsonObject
                assertEquals("Old item", oldItem.getValue("name").jsonPrimitive.content)
                assertEquals(99, oldItem.getValue("quantity").jsonPrimitive.int)
            }
            val untouched = ditto.store.execute("SELECT * FROM pos_orders") { it.decode<Order>() }
            assertEquals(listOf(order), untouched)
        }
    }

    private suspend fun <T> Channel<T>.await(predicate: (T) -> Boolean): T = withTimeout(5_000) {
        var value = receive()
        while (!predicate(value)) value = receive()
        value
    }

    private suspend fun TestDitto.readItem(id: DocumentID): SaleItem = ditto.store.execute(
        "SELECT * FROM sale_items_v2 WHERE _id.id = :id AND _id.locationId = :locationId",
        mapOf("id" to id.id, "locationId" to id.locationId)
    ) { it.decode<SaleItem>().single() }
}
