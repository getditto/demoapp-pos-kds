package live.ditto.pos.core.data.images

import android.graphics.Color
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.runBlocking
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.SaleItemCreation
import live.ditto.pos.core.data.SaleItemMetadata
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.data.decode
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.presentation.images.OrderLinePhoto
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class OrderLinePhotoTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun orderPhotoRendersRecordedImageAfterCatalogReplacement() = runBlocking {
        TestDitto.withInstance {
            val id = DocumentID("coffee", "A")
            val catalog = catalog()
            catalog.create(SaleItemCreation(SaleItemMetadata(id, "Coffee", Price(199)), 1))
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.RED, 63, 63), "image/png", ditto.store).use { red ->
                PhotoAttachments.replace(red, id, ditto.store)
                val sale = ditto.store.execute("SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to id.id, "locationId" to id.locationId)) { it.decode<SaleItem>().single() }
                val order = Order.new("A").addingCartLineItem(CartLineItem.from(sale), "line")
                repository().upsert(order)
                PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { blue ->
                    PhotoAttachments.replace(blue, id, ditto.store)
                    val recorded = read(order.documentId)
                    compose.setContent {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            OrderLinePhoto(recorded.cart.getValue("line"), recorded.documentId, ditto.store, Modifier.size(56.dp).testTag("photo"))
                        }
                    }
                    var lastPixel = androidx.compose.ui.graphics.Color.Unspecified
                    try {
                        compose.waitUntil(5_000) {
                            val pixels = compose.onNodeWithTag("photo").captureToImage().toPixelMap()
                            val pixel = pixels[pixels.width / 2, pixels.height / 2]
                            lastPixel = pixel
                            pixel.red > 0.99f && pixel.green < 0.01f && pixel.blue < 0.01f
                        }
                    } catch (error: androidx.compose.ui.test.ComposeTimeoutException) {
                        throw AssertionError("Recorded photo pixel: $lastPixel; ref=${recorded.cart.getValue("line").image}", error)
                    }
                    val pixels = compose.onNodeWithTag("photo").captureToImage().toPixelMap()
                    assertEquals(androidx.compose.ui.graphics.Color.Red, pixels[pixels.width / 2, pixels.height / 2])
                }
            }
        }
    }
}
