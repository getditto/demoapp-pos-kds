package live.ditto.pos.core.data.images

import android.graphics.Color
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.runBlocking
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItemCreation
import live.ditto.pos.core.data.SaleItemMetadata
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.presentation.images.PhotoImageCache
import live.ditto.pos.core.presentation.images.PhotoLoader
import live.ditto.pos.core.presentation.images.ProductPhoto
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicLong

class ProductPhotoTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun observedCatalogDrivesPhotoViewReplacementReuseRemovalAndVisibility() = runBlocking {
        TestDitto.withInstance {
            val id = DocumentID("coffee", "A")
            val repository = catalog()
            repository.create(SaleItemCreation(SaleItemMetadata(id, "Coffee", "coffee", Price(199)), 2))
            val requests = CopyOnWriteArrayList<PhotoReference>()
            val canceled = CopyOnWriteArrayList<Int>()
            val observedQuantity = AtomicLong()
            var visible by mutableStateOf(true)
            var owner by mutableStateOf(id)
            compose.setContent {
                val scope = rememberCoroutineScope()
                val loader = remember {
                    PhotoLoader(scope, PhotoImageCache()) { reference ->
                        val index = requests.size
                        requests.add(reference)
                        try {
                            awaitCancellation()
                        } finally {
                            canceled.add(index)
                        }
                    }
                }
                if (visible) {
                    val items by remember(repository) { repository.observeLocationSaleItems(id.locationId) }.collectAsState(initial = emptyList())
                    SideEffect { observedQuantity.set(items.firstOrNull()?.quantity ?: 0) }
                    ProductPhoto(items.firstOrNull()?.image, owner, loader, Modifier.size(40.dp))
                }
            }
            PhotoAttachments.importPhoto(PhotoTestImages.png(Color.RED), "image/png", ditto.store).use { a ->
                PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", ditto.store).use { b ->
                    PhotoAttachments.replace(a, id, ditto.store)
                    compose.waitUntil { requests.size == 1 }
                    assertEquals(a.id, requests.first().id)
                    repository.increment(1, id)
                    compose.waitUntil { observedQuantity.get() == 3L }
                    assertEquals(1, requests.size)
                    PhotoAttachments.replace(b, id, ditto.store)
                    compose.waitUntil { requests.size == 2 }
                    assertEquals(b.id, requests.last().id)
                    assertEquals(listOf(0), canceled.toList())
                    PhotoAttachments.remove(id, ditto.store)
                    compose.waitUntil { canceled.toList() == listOf(0, 1) }
                    PhotoAttachments.replace(a, id, ditto.store)
                    compose.waitUntil { requests.size == 3 }
                    compose.runOnIdle { owner = id.copy(locationId = "B") }
                    compose.waitUntil { requests.size == 4 }
                    assertEquals(listOf(0, 1, 2), canceled.toList())
                    compose.runOnIdle { visible = false }
                    compose.waitUntil { canceled.toList() == listOf(0, 1, 2, 3) }
                    compose.runOnIdle { visible = true }
                    compose.waitUntil { requests.size == 5 }
                    compose.runOnIdle { visible = false }
                    compose.waitUntil { canceled.toList() == listOf(0, 1, 2, 3, 4) }
                }
            }
        }
    }
}
