package live.ditto.pos.core.data.images

import android.graphics.Color
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.SaleItemCreation
import live.ditto.pos.core.data.SaleItemMetadata
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.data.decodeOrSkip
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PhotoAttachmentsTest {
    @Test
    fun optionalPhotosPreserveStockMetadataAndLocationIdentity() = runBlocking {
        TestDitto.withInstance {
            val id = DocumentID("coffee'冰", "A")
            val other = id.copy(locationId = "B")
            val repository = catalog()
            val metadata = SaleItemMetadata(id, "Coffee", Price(199))
            repository.create(SaleItemCreation(metadata, 2))
            repository.create(SaleItemCreation(SaleItemMetadata(other, "Other", Price(250)), 7))
            repository.increment(-4, id)
            PhotoAttachments.configure(ditto.store)
            ditto.store.execute("SHOW attachments_auto_fetch") { result ->
                assertEquals(true, result.items.single().value["attachments_auto_fetch"].boolean)
            }

            val aData = PhotoTestImages.stockPhoto
            PhotoAttachments.importPhoto(aData, "image/png", ditto.store).use { a ->
                PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { b ->
                    coroutineScope {
                        val ready = CompletableDeferred<Unit>()
                        val observedReplacement = CompletableDeferred<SaleItem>()
                        val observation = launch {
                            val items = repository.observeLocationSaleItems(id.locationId).onEach { ready.complete(Unit) }
                                .first { rows -> rows.any { it.documentId == id && it.image?.id == b.id } }
                            observedReplacement.complete(items.single { it.documentId == id })
                        }
                        ready.await()
                        try {
                            PhotoAttachments.replace(a, id, ditto.store)
                            val photo = readItem(id)
                            assertEquals(PhotoAttachments.reference(a), photo.image)
                            assertArrayEquals(aData, a.getData())
                            assertEquals(metadata, photo.metadata)
                            assertEquals(-2L, photo.quantity)
                            val foreign = readItem(other)
                            assertNull(foreign.image)
                            assertEquals(7L, foreign.quantity)

                            val renamed = metadata.copy(name = "Renamed", price = Price(0))
                            repository.updateMetadata(renamed)
                            val updated = readItem(id)
                            assertEquals(photo.image, updated.image)
                            assertEquals(-2L, updated.quantity)
                            PhotoAttachments.replace(b, id, ditto.store)
                            assertEquals(-2L, withTimeout(5_000) { observedReplacement.await() }.quantity)
                            val replaced = readItem(id)
                            assertEquals(PhotoAttachments.reference(b), replaced.image)
                            assertNotEquals(photo.image?.id, replaced.image?.id)
                            PhotoAttachments.remove(id, ditto.store)
                            val removed = readItem(id)
                            assertNull(removed.image)
                            assertEquals(renamed, removed.metadata)
                            assertEquals(-2L, removed.quantity)
                            ditto.store.execute("SELECT image FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId)) {
                                assertFalse(it.items.single().value.dictionary.keys.any { key -> key.string == "image" })
                            }
                        } finally {
                            observation.cancelAndJoin()
                        }
                    }
                }
            }
        }
    }

    private suspend fun TestDitto.readItem(id: DocumentID): SaleItem = ditto.store.execute(
        "SELECT * FROM COLLECTION sale_items (image ATTACHMENT) WHERE _id.id = :id AND _id.locationId = :locationId",
        mapOf("id" to id.id, "locationId" to id.locationId)
    ) { it.decodeOrSkip<SaleItem>().single() }
}
