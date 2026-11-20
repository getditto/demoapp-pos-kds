package live.ditto.pos.core.presentation.images

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.annotation.MainThread
import com.ditto.kotlin.DittoAttachmentFetchResult
import com.ditto.kotlin.DittoStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.images.PhotoReference

class PhotoImageCache {
    private val images = object : LruCache<String, Bitmap>(16 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.allocationByteCount
    }

    operator fun get(id: String): Bitmap? = images.get(id)
    operator fun set(id: String, image: Bitmap) {
        images.put(id, image)
    }

    companion object {
        val shared = PhotoImageCache()
    }
}

@MainThread
class PhotoLoader(
    private val scope: CoroutineScope,
    private val cache: PhotoImageCache = PhotoImageCache.shared,
    private val fetch: suspend (PhotoReference) -> ByteArray?
) {
    private val mutableImage = MutableStateFlow<Bitmap?>(null)
    val image = mutableImage.asStateFlow()
    private var owner: DocumentID? = null
    private var referenceId: String? = null
    private var generation = 0
    private var job: Job? = null

    fun update(reference: PhotoReference?, owner: DocumentID): Job? {
        if (this.owner == owner && referenceId == reference?.id) return job
        stop()
        this.owner = owner
        referenceId = reference?.id
        if (reference == null) return null
        cache[reference.id]?.let {
            mutableImage.value = it
            return null
        }
        val request = generation
        job = scope.launch {
            try {
                val data = fetch(reference)
                val bitmap = withContext(Dispatchers.Default) {
                    data?.let {
                        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                        BitmapFactory.decodeByteArray(it, 0, it.size, bounds)
                        var sample = 1
                        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 512) sample *= 2
                        BitmapFactory.decodeByteArray(it, 0, it.size, BitmapFactory.Options().apply { inSampleSize = sample })
                    }
                }
                ensureActive()
                if (generation == request) {
                    bitmap?.let { cache[reference.id] = it }
                    mutableImage.value = bitmap
                }
            } catch (canceled: CancellationException) {
                throw canceled
            } catch (_: Exception) {
                if (generation == request) mutableImage.value = null
            }
        }
        return job
    }

    fun stop() {
        generation++
        job?.cancel()
        job = null
        owner = null
        referenceId = null
        mutableImage.value = null
    }

    fun matches(reference: PhotoReference?): Boolean = referenceId == reference?.id

    companion object {
        fun from(store: DittoStore, scope: CoroutineScope): PhotoLoader = PhotoLoader(scope) { reference ->
            // SDK auto-fetch transfers bytes; this UI-owned fetch is canceled with the image.
            // https://docs.ditto.live/sdk/latest/crud/working-with-attachments#fetching-attachments
            when (val result = store.fetchAttachment(reference.token())) {
                is DittoAttachmentFetchResult.Completed -> result.attachment.use { it.getData() }
                is DittoAttachmentFetchResult.Deleted -> null
            }
        }
    }
}
