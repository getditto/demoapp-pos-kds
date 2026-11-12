package live.ditto.pos.core.data.images

import android.graphics.Color
import com.ditto.kotlin.DittoStore
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.presentation.images.PhotoImageCache
import live.ditto.pos.core.presentation.images.PhotoLoader
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class PhotoLoaderTest {
    private val owner = DocumentID("coffee", "A")
    private val a = PhotoReference("A", 1uL, emptyMap())
    private val b = PhotoReference("B", 1uL, emptyMap())

    @Test
    fun referenceAndOwnerChangesCancelAndRejectObsoleteCompletions() = runBlocking {
        withContext(Dispatchers.Main) {
            coroutineScope {
                val source = ControlledPhotos()
                val loader = PhotoLoader(this, PhotoImageCache(), source::fetch)
                try {
                    loader.update(a, owner)
                    val first = source.next()
                    loader.update(a, owner)
                    assertEquals(1, source.requests)
                    loader.update(b, owner)
                    val second = source.next()
                    assertEquals(1, source.canceled)
                    second.data.complete(PhotoTestImages.png(Color.BLUE))
                    val current = withTimeout(5_000) { loader.image.first { it != null } }
                    assertFalse(loader.matches(a))
                    assertTrue(loader.matches(b))
                    first.data.complete(PhotoTestImages.png(Color.RED))
                    assertSame(current, loader.image.value)
                    loader.update(null, owner)
                    assertNull(loader.image.value)
                    loader.update(a, owner)
                    val third = source.next()
                    loader.update(a, owner.copy(locationId = "B"))
                    val fourth = source.next()
                    assertEquals(2, source.canceled)
                    third.data.complete(PhotoTestImages.png(Color.RED))
                    assertNull(loader.image.value)
                    loader.stop()
                    fourth.data.complete(PhotoTestImages.png(Color.RED))
                    assertNull(loader.image.value)
                } finally {
                    loader.stop()
                }
            }
        }
    }

    @Test
    fun cachedImagesSurviveOfflineReuseAndCorruptDataUsesThePlaceholder() = runBlocking {
        withContext(Dispatchers.Main) {
            coroutineScope {
                val source = ControlledPhotos()
                val loader = PhotoLoader(this, PhotoImageCache(), source::fetch)
                try {
                    loader.update(a, owner)
                    source.next().data.complete(PhotoTestImages.png(Color.RED))
                    val cached = withTimeout(5_000) { loader.image.first { it != null } }
                    loader.stop()
                    loader.update(a, DocumentID("other", "B"))
                    assertSame(cached, loader.image.value)
                    assertEquals(1, source.requests)
                    val pending = loader.update(b, owner)
                    assertNull(loader.image.value)
                    val corrupt = source.next()
                    corrupt.data.complete("corrupt".toByteArray())
                    pending?.join()
                    assertNull(loader.image.value)
                    loader.update(a, owner)
                    assertSame(cached, loader.image.value)
                } finally {
                    loader.stop()
                }
            }
        }
    }

    @Test
    fun sdkFileAvailabilityUpdatesTheImageWithoutAnotherDocumentResultAndStopReleasesTheFetcher() = runBlocking {
        TestDitto.withInstance {
            val origin = ditto
            val data = PhotoTestImages.png(Color.RED)
            PhotoAttachments.importPhoto(data, "image/png", origin.store).use { attachment ->
                val reference = PhotoAttachments.reference(attachment)
                TestDitto.withInstance {
                    val receiver = ditto
                    receive(reference, receiver.store)
                    withContext(Dispatchers.Main) {
                        coroutineScope {
                            val loader = PhotoLoader.from(receiver.store, this)
                            try {
                                loader.update(reference, owner)
                                assertNull(loader.image.value)
                                awaitFetchers(receiver.store, 1)
                                PhotoAttachments.importPhoto(data, "image/png", receiver.store).use { local ->
                                    assertEquals(attachment.id, local.id)
                                    assertNotNull(withTimeout(5_000) { loader.image.first { it != null } })
                                }
                                loader.stop()
                                awaitFetchers(receiver.store, 0)
                                PhotoAttachments.importPhoto(PhotoTestImages.png(Color.BLUE), "image/png", origin.store).use { missing ->
                                    val missingReference = PhotoAttachments.reference(missing)
                                    receive(missingReference, receiver.store)
                                    loader.update(missingReference, owner)
                                    awaitFetchers(receiver.store, 1)
                                    loader.stop()
                                    awaitFetchers(receiver.store, 0)
                                }
                            } finally {
                                loader.stop()
                            }
                        }
                    }
                }
            }
        }
    }

    private suspend fun receive(reference: PhotoReference, store: DittoStore) {
        // A received document introduces the token before its separately transferred file.
        store.execute(
            "INSERT INTO sale_items INITIAL DOCUMENTS (:document)",
            mapOf("document" to mapOf("_id" to mapOf("id" to owner.id, "locationId" to owner.locationId)))
        )
        store.execute(
            "UPDATE COLLECTION sale_items (image ATTACHMENT) SET image = :image WHERE _id.id = :id AND _id.locationId = :locationId",
            mapOf("id" to owner.id, "locationId" to owner.locationId, "image" to reference.token())
        )
    }

    private suspend fun awaitFetchers(store: DittoStore, count: Int) = withTimeout(5_000) {
        while (store.attachmentFetchers.size != count) delay(10)
    }

    private class ControlledPhotos {
        data class Request(val reference: PhotoReference, val data: CompletableDeferred<ByteArray?> = CompletableDeferred())
        private val queued = Channel<Request>(Channel.UNLIMITED)
        var requests = 0
        var canceled = 0

        suspend fun fetch(reference: PhotoReference): ByteArray? {
            val request = Request(reference)
            requests++
            queued.send(request)
            return try {
                request.data.await()
            } finally {
                if (!request.data.isCompleted) canceled++
            }
        }

        suspend fun next(): Request = withTimeout(5_000) { queued.receive() }
    }
}
