package live.ditto.pos.core.data

import android.graphics.Color
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.images.PhotoAttachments
import live.ditto.pos.core.data.images.PhotoTestImages
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.presentation.images.PhotoLoader
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OrderPhotosTest {
    @Test
    fun quantityChangesKeepCapturedDetailsAndRemovalThenReaddCapturesCurrentCatalog() = runBlocking {
        TestDitto.withInstance {
            val catalog = catalog()
            val orders = repository()
            val id = DocumentID("coffee", "A")
            val metadata = SaleItemMetadata(id, "Original", Price(199))
            catalog.create(SaleItemCreation(metadata, 2))
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.RED), "image/png", ditto.store).use { a ->
                PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { b ->
                    val withoutPhoto = CartLineItem.from(sale(id), 1)
                    PhotoAttachments.replace(a, id, ditto.store)
                    val captured = CartLineItem.from(sale(id), 1)
                    var order = Order.new("A").addingCartLineItem(captured, "line`photo")
                        .addingCartLineItem(withoutPhoto, "no-photo")
                    orders.upsert(order)
                    val saved = read(order.documentId)
                    assertEquals(captured.image, saved.cart["line`photo"]?.image)
                    assertNull(saved.cart["no-photo"]?.image)
                    order = saved

                    catalog.updateMetadata(metadata.copy(name = "Renamed", price = Price(250)))
                    PhotoAttachments.replace(b, id, ditto.store)
                    catalog.increment(-4, id)
                    val current = sale(id)
                    order = order.addingCartLineItem(CartLineItem.from(current, 3), "line`photo")
                        .addingCartLineItem(CartLineItem.from(current, 2), "no-photo")
                    orders.upsert(order)
                    val edited = read(order.documentId)
                    assertEquals(saved.cart["line`photo"]?.copy(qty = 3), edited.cart["line`photo"])
                    assertNull(edited.cart["no-photo"]?.image)
                    assertEquals("Original", edited.cart["no-photo"]?.name)
                    assertEquals(-2L, current.quantity)

                    orders.clearCart(edited)
                    val removed = read(order.documentId)
                    assertNull(removed.cart["line`photo"])
                    val readded = CartLineItem.from(current, 1)
                    orders.upsert(removed.addingCartLineItem(readded, "line`photo"))
                    val savedReadd = read(order.documentId).cart["line`photo"]
                    assertEquals(readded.name, savedReadd?.name)
                    assertEquals(readded.price, savedReadd?.price)
                    assertEquals(readded.image, savedReadd?.image)
                    assertEquals(readded.createdAt.toDittoIsoString(), savedReadd?.createdAt?.toDittoIsoString())
                    assertEquals(PhotoAttachments.reference(b), readded.image)
                }
            }
        }
    }

    @Test
    fun paymentAndStatusPatchesPreserveOtherMapsPhotosAndLocationAndClearRemovesLines() = runBlocking {
        TestDitto.withInstance {
            val data = PhotoTestImages.stockPhoto
            PhotoAttachments.importPhoto(data, "image/png", ditto.store).use { attachment ->
                val fixture = TestDitto.fixture()
                val line = fixture.cart.values.first().copy(image = PhotoAttachments.reference(attachment))
                val order = fixture.copy(cart = mapOf("line`photo" to line))
                val other = order.copy(documentId = order.documentId.copy(locationId = "B"))
                val orders = repository()
                orders.upsert(order)
                orders.upsert(other)
                val catalog = catalog()
                val saleId = DocumentID(line.saleItemId, order.documentId.locationId)
                catalog.create(SaleItemCreation(SaleItemMetadata(saleId, line.name, line.price), 1))
                PhotoAttachments.replace(attachment, saleId, ditto.store)
                val payment = Payment(PaymentType.CASH, order.total, createdAt = order.createdAt)
                val date = order.createdAt + kotlin.time.Duration.parse("100s")
                orders.addPayment(payment, "payment`new", order.documentId)
                live.ditto.pos.core.data.orders.OrderCommands.updateStatus(OrderStatus.PROCESSED, order.documentId, ditto.store, date)
                val paid = read(order.documentId)
                assertEquals(order.addingPayment(payment, "payment`new").appendingStatus(OrderStatus.PROCESSED, date), paid)
                assertEquals(other, read(other.documentId))
                ditto.store.execute("DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to saleId.id, "locationId" to saleId.locationId))
                assertEquals(paid, read(order.documentId))
                // Historical lines render from their own references without a catalog document.
                kotlinx.coroutines.coroutineScope {
                    val loader = PhotoLoader.from(ditto.store, this)
                    try {
                        loader.update(paid.cart["line`photo"]?.image, paid.documentId)?.join()
                        withTimeout(5_000) { loader.image.first { it != null } }
                        assertArrayEquals(data, attachment.getData())
                    } finally {
                        loader.stop()
                    }
                }
                orders.clearCart(paid)
                val cleared = read(order.documentId)
                assertTrue(cleared.cart.isEmpty())
                assertEquals(paid.payments, cleared.payments)
                assertEquals(paid.statusLog, cleared.statusLog)
                assertEquals(other, read(other.documentId))
                assertArrayEquals(data, attachment.getData())
            }
        }
    }

    @Test
    fun captureDoesNotRequireFileAndLaterAvailabilityLoadsTheFrozenReference() = runBlocking {
        TestDitto.withInstance {
            val data = PhotoTestImages.png(Color.RED, width = 31, height = 31)
            PhotoAttachments.importPhoto(data, "image/png", ditto.store).use { attachment ->
                val reference = PhotoAttachments.reference(attachment)
                TestDitto.withInstance {
                    val line = CartLineItem(saleItemId = "coffee", name = "Coffee", price = Price(199), image = reference)
                    val order = Order.new("A").addingCartLineItem(line, "line")
                    repository().upsert(order)
                    val received = read(order.documentId)
                    assertEquals(reference, received.cart["line"]?.image)
                    assertFalse(order.dittoJsonString().contains("imageName"))
                    assertTrue(ditto.store.attachmentFetchers.isEmpty())
                    kotlinx.coroutines.coroutineScope {
                        val loader = PhotoLoader.from(ditto.store, this)
                        try {
                            loader.update(received.cart["line"]?.image, received.documentId)
                            withTimeout(5_000) { while (ditto.store.attachmentFetchers.isEmpty()) kotlinx.coroutines.yield() }
                            assertNull(loader.image.value)
                            PhotoAttachments.importPhoto(data, "image/png", ditto.store).use { local ->
                                assertEquals(reference.id, local.id)
                                withTimeout(5_000) { loader.image.first { it != null } }
                            }
                            assertEquals(received, read(order.documentId))
                        } finally {
                            loader.stop()
                        }
                    }
                }
            }
        }
    }

    private suspend fun TestDitto.sale(id: DocumentID): SaleItem = ditto.store.execute(
        "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId",
        mapOf("id" to id.id, "locationId" to id.locationId)
    ) { it.decode<SaleItem>().single() }
}
