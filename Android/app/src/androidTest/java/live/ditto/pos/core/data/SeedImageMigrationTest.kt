package live.ditto.pos.core.data

import android.graphics.Color
import com.ditto.kotlin.DittoAttachmentFetchResult
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonObject
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.core.data.demo.SaleItemSeed
import live.ditto.pos.core.data.demo.SeedImageMigration
import live.ditto.pos.core.data.images.PhotoAttachments
import live.ditto.pos.core.data.images.PhotoReference
import live.ditto.pos.core.data.images.PhotoTestImages
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.legacy.LegacyCartLineItem
import live.ditto.pos.legacy.LegacyDemoSeeder
import live.ditto.pos.legacy.LegacyLocationSeed
import live.ditto.pos.legacy.LegacyOrder
import live.ditto.pos.legacy.LegacySaleItem
import live.ditto.pos.legacy.LegacySaleItemSeed
import live.ditto.pos.legacy.write
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.time.Instant

class SeedImageMigrationTest {
    @Test
    fun productionInitialPayloadsExactlyMatchPinnedLegacySerialization() {
        assertEquals(LegacySaleItemSeed.saleItemsForAllLocations().map { it.dittoJsonString() }, SaleItemSeed.initialDocuments())
        assertEquals(LegacyLocationSeed.demoLocations.map { it.dittoJsonString() }, LocationSeed.demoLocations.map { it.dittoJsonString() })
        val item = SaleItemSeed.saleItemsForAllLocations().first()
        assertFalse(SaleItemCreation(item.metadata, 1).json().contains("imageName"))
        assertFalse(CartLineItem.from(item).dittoJsonString().contains("imageName"))
    }

    @Test
    fun actualBootstrapAttachesPreparedBytesInBothExactSeederArrivalOrders() = runBlocking {
        for (oldFirst in listOf(true, false)) {
            TestDitto.withInstance {
                val old = LegacyDemoSeeder(ditto)
                val current = DemoSeeder(ditto, bundledPhotos)
                if (oldFirst) old.seedAll()
                current.seedAll()
                old.seedAll()
                current.seedAll()
                val items = ditto.store.execute("SELECT * FROM sale_items") { it.decode<SaleItem>() }
                assertEquals(LegacySaleItemSeed.saleItemsForAllLocations().map { it.documentId }.toSet(), items.map { it.documentId }.toSet())
                for (item in items) {
                    assertEquals(20L, item.quantity)
                    val expected = checkNotNull(expectedPhoto(item.documentId))
                    assertArrayEquals(expected, photoBytes(checkNotNull(item.image)))
                }
                assertTrue(ditto.store.execute("SELECT * FROM sale_items WHERE imageName IS NOT MISSING") { it.decode<JsonObject>() }.isEmpty())
            }
        }
    }

    @Test
    fun migrationPreservesCustomAndRemovedPhotosStockMetadataDeletionAndOtherLocations() = runBlocking {
        TestDitto.withInstance {
            LegacyDemoSeeder(ditto).seedAll()
            val catalog = catalog()
            val custom = DocumentID("00001", "00001")
            val absent = DocumentID("00008", "00001")
            val deleted = DocumentID("00013", "00001")
            val unknown = DocumentID("custom", "00001")
            val wrongMenu = DocumentID("00001", "00002")
            catalog.restart(0, custom)
            catalog.increment(-4, custom)
            catalog.restart(0, absent)
            catalog.updateMetadata(SaleItemMetadata(custom, "Edited", Price(0)))
            val misleading = DocumentID("00012", "00001")
            ditto.store.execute("UPDATE sale_items SET name = :name, imageName = :imageName WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("name" to "Burger", "imageName" to "burger", "id" to misleading.id, "locationId" to misleading.locationId))
            for (id in listOf(unknown, wrongMenu)) {
                val old = LegacySaleItem.seed(id.id, id.locationId, "Custom", "burger", 123)
                ditto.store.execute("INSERT INTO sale_items DOCUMENTS (deserialize_json(:json))", mapOf("json" to old.dittoJsonString()))
            }
            ditto.store.execute("DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to deleted.id, "locationId" to deleted.locationId))
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { photo ->
                PhotoAttachments.replace(photo, custom, ditto.store)
                // A converted item with a removed photo has no legacy field left to consume.
                ditto.store.execute("UPDATE sale_items UNSET imageName WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to absent.id, "locationId" to absent.locationId))
                PhotoAttachments.remove(absent, ditto.store)
                SeedImageMigration(ditto.store, bundledPhotos).upgradeCatalog("00001")
                assertArrayEquals(expectedPhoto(misleading), photoBytes(checkNotNull(sale(misleading).image)))
                assertEquals(PhotoAttachments.reference(photo), sale(custom).image)
                assertEquals(-4L, sale(custom).quantity)
                assertEquals("Edited", sale(custom).name)
                assertEquals(0, sale(custom).price.amount)
                assertNull(sale(absent).image)
                assertEquals(0L, sale(absent).quantity)
                assertNull(sale(unknown).image)
                val other = rawSale(wrongMenu)
                assertTrue("imageName" in other)
                assertFalse("image" in other)
                assertTrue(ditto.store.execute("SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to deleted.id, "locationId" to deleted.locationId)) { it.decode<SaleItem>() }.isEmpty())
                val before = rawSale(custom)
                SeedImageMigration(ditto.store, bundledPhotos).upgradeCatalog("00001")
                assertEquals(before, rawSale(custom))
                SeedImageMigration(ditto.store, bundledPhotos).upgradeCatalog("00002")
                assertNull(sale(wrongMenu).image)
                assertFalse("imageName" in rawSale(wrongMenu))
            }
        }
    }

    @Test
    fun visibleObserversPrepareLateLegacyCatalogAndOrdersAndReentryHasNoHiddenFeed() = runBlocking {
        TestDitto.withInstance {
            coroutineScope {
                val catalogEvents = Channel<List<SaleItem>>(Channel.UNLIMITED)
                val orderEvents = Channel<List<Order>>(Channel.UNLIMITED)
                val catalog = catalog()
                val orders = repository()
                val catalogObservation = launch { catalog.observeLocationSaleItems("00001").collect { catalogEvents.send(it) } }
                var orderObservation = launch { orders.observeLocationOrders("00001").collect { orderEvents.send(it) } }
                try {
                    catalogEvents.await { it.isEmpty() }
                    orderEvents.await { it.isEmpty() }
                    LegacyDemoSeeder(ditto).seedAll()
                    val prepared = catalogEvents.await { it.size == 7 }
                    assertTrue(prepared.all { it.quantity == 20L && it.image != null })
                    val old = oldOrder("late")
                    old.write(ditto.store)
                    val observed = orderEvents.await { it.singleOrNull()?.documentId == old.documentId }.single()
                    assertArrayEquals(expectedPhoto(DocumentID("00001", "00001")), photoBytes(checkNotNull(observed.cart["line`one"]?.image)))
                    orderObservation.cancelAndJoin()
                    catalogObservation.cancelAndJoin()
                    assertTrue(ditto.store.observers.isEmpty())
                    val hidden = oldOrder("hidden")
                    hidden.write(ditto.store)
                    assertTrue("imageName" in rawOrder(hidden.documentId).getValue("cart").let { it as JsonObject }.getValue("line`one").let { it as JsonObject })
                    orderObservation = launch { orders.observeLocationOrders("00001").collect { orderEvents.send(it) } }
                    val returned = orderEvents.await { rows -> rows.any { it.documentId == hidden.documentId && it.cart["line`one"]?.image != null } }
                    assertEquals(2, returned.size)
                } finally {
                    orderObservation.cancelAndJoin()
                    catalogObservation.cancelAndJoin()
                    catalogEvents.close()
                    orderEvents.close()
                }
            }
        }
    }

    @Test
    fun orderMigrationUsesRecordedSourceAndPreservesFrozenPhotosAbsenceAndUnrelatedMaps() = runBlocking {
        TestDitto.withInstance {
            LegacyDemoSeeder(ditto).seedAll()
            val old = oldOrder("frozen")
            old.write(ditto.store)
            val unknown = old.cart.getValue("line`one").copy(saleItemId = "custom", imageName = "burger")
            val noPhoto = old.cart.getValue("line`one").copy(saleItemId = "00008")
            old.copy(cart = old.cart + ("unknown" to unknown) + ("absent" to noPhoto)).write(ditto.store)
            ditto.store.execute("UPDATE pos_orders UNSET cart.`absent`.imageName WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to old.documentId.id, "locationId" to old.documentId.locationId))
            val before = rawOrder(old.documentId)
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { custom ->
                val id = DocumentID("00001", "00001")
                PhotoAttachments.replace(custom, id, ditto.store)
                val prepared = checkNotNull(repository().findOrder(old.documentId))
                val frozen = checkNotNull(prepared.cart["line`one"]?.image)
                assertArrayEquals(expectedPhoto(id), photoBytes(frozen))
                assertTrue(frozen.id != custom.id)
                assertNull(prepared.cart["unknown"]?.image)
                assertNull(prepared.cart["absent"]?.image)
                assertEquals("Recorded burger", prepared.cart["line`one"]?.name)
                assertEquals(17, prepared.cart["line`one"]?.price?.amount)
                assertEquals(3, prepared.cart["line`one"]?.qty)
                val after = rawOrder(old.documentId)
                for (key in listOf("payments", "status_log", "createdAt")) assertEquals(before[key], after[key])
                PhotoAttachments.remove(id, ditto.store)
                ditto.store.execute("DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId))
                old.write(ditto.store)
                val replayed = checkNotNull(repository().findOrder(old.documentId))
                assertEquals(frozen, replayed.cart["line`one"]?.image)
                assertArrayEquals(expectedPhoto(id), photoBytes(frozen))
                assertFalse((rawOrder(old.documentId)["cart"] as JsonObject).values.any { it is JsonObject && "imageName" in it })
                assertNotNull(replayed.cart["unknown"])
                assertNull(replayed.cart["unknown"]?.image)
            }
        }
    }

    private fun oldOrder(id: String): LegacyOrder = LegacyOrder(
        DocumentID(id, "00001"),
        cart = mapOf("line`one" to LegacyCartLineItem("00001", "Recorded burger", "coffee", Price(17), 3, Instant.parse("2026-04-01T10:00:00.000Z"))),
        payments = mapOf("payment" to Payment(PaymentType.CASH, Price(51), createdAt = Instant.parse("2026-04-01T10:01:00.000Z"))),
        statusLog = mapOf("2026-04-01T10:01:00.000Z" to "Processed"),
        createdAt = Instant.parse("2026-04-01T10:00:00.000Z")
    )

    private fun expectedPhoto(id: DocumentID): ByteArray {
        val fixture = LegacySaleItemSeed.saleItemsForAllLocations().single { it.documentId == id }
        val resourceName = "stock_${if (fixture.imageName == "corn") "corn_on_cob" else fixture.imageName}"
        val context = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext
        val resource = context.resources.getIdentifier(resourceName, "raw", context.packageName)
        check(resource != 0) { "Missing independently named prepared file $resourceName" }
        return context.resources.openRawResource(resource).use { it.readBytes() }
    }

    private suspend fun TestDitto.sale(id: DocumentID): SaleItem = ditto.store.execute("SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId)) { it.decode<SaleItem>().single() }
    private suspend fun TestDitto.rawSale(id: DocumentID): JsonObject = ditto.store.execute("SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId)) { it.decode<JsonObject>().single() }
    private suspend fun TestDitto.rawOrder(id: DocumentID): JsonObject = ditto.store.execute("SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId)) { it.decode<JsonObject>().single() }
    private suspend fun TestDitto.photoBytes(reference: PhotoReference): ByteArray = when (val result = ditto.store.fetchAttachment(reference.token())) {
        is DittoAttachmentFetchResult.Completed -> result.attachment.use { it.getData() }
        is DittoAttachmentFetchResult.Deleted -> error("Expected local prepared photo")
    }
    private suspend fun <T> Channel<T>.await(predicate: (T) -> Boolean): T = withTimeout(10_000) {
        var value = receive()
        while (!predicate(value)) value = receive()
        value
    }
}
