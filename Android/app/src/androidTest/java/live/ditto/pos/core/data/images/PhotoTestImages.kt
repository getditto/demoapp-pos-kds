package live.ditto.pos.core.data.images

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

internal object PhotoTestImages {
    val stockPhoto: ByteArray
        get() = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext.resources
            .openRawResource(live.ditto.pos.R.drawable.burger).use { it.readBytes() }

    val colors = listOf(android.graphics.Color.RED, android.graphics.Color.GREEN, android.graphics.Color.BLUE, android.graphics.Color.YELLOW)

    fun png(color: Int, width: Int = 32, height: Int = 32): ByteArray {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        return try {
            bitmap.eraseColor(color)
            ByteArrayOutputStream().use { output ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, output))
                output.toByteArray()
            }
        } finally {
            bitmap.recycle()
        }
    }

    fun pattern(width: Int, height: Int, noise: Boolean = false): Bitmap {
        var seed = 42u
        val pixels = IntArray(width * height) { index ->
            if (noise) {
                seed = seed * 1664525u + 1013904223u
                android.graphics.Color.rgb((seed shr 24).toInt() and 255, (seed shr 16).toInt() and 255, (seed shr 8).toInt() and 255)
            } else {
                colors[(if (index / width < height / 2) 0 else 2) + if (index % width < width / 2) 0 else 1]
            }
        }
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }

    fun encode(bitmap: Bitmap, format: Bitmap.CompressFormat = Bitmap.CompressFormat.PNG): ByteArray =
        ByteArrayOutputStream().use { stream ->
            check(bitmap.compress(format, 100, stream))
            stream.toByteArray()
        }
}
