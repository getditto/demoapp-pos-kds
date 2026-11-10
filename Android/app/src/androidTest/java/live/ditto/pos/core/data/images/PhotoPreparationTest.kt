package live.ditto.pos.core.data.images

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.ExifInterface
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import kotlin.math.abs

class PhotoPreparationTest {
    @Test
    fun preparationNormalizesAllExifRotationsAndMirrorsBeforeCropping() {
        val expected = listOf(
            listOf(0, 1, 2, 3),
            listOf(1, 0, 3, 2),
            listOf(3, 2, 1, 0),
            listOf(2, 3, 0, 1),
            listOf(0, 2, 1, 3),
            listOf(2, 0, 3, 1),
            listOf(3, 1, 2, 0),
            listOf(1, 3, 0, 2)
        )
        val source = PhotoTestImages.pattern(120, 80)
        try {
            for (orientation in 1..8) {
                val file = File.createTempFile("photo-orientation", ".jpg", InstrumentationRegistry.getInstrumentation().targetContext.cacheDir)
                try {
                    file.writeBytes(PhotoTestImages.encode(source, Bitmap.CompressFormat.JPEG))
                    ExifInterface(file).apply {
                        setAttribute(ExifInterface.TAG_ORIENTATION, orientation.toString())
                        saveAttributes()
                    }
                    val prepared = PhotoPreparation.prepare(file.readBytes())
                    val image = requireNotNull(BitmapFactory.decodeByteArray(prepared.data, 0, prepared.data.size))
                    try {
                        assertEquals(80, image.width)
                        assertEquals(80, image.height)
                        listOf(20 to 20, 60 to 20, 20 to 60, 60 to 60).forEachIndexed { index, point ->
                            val pixel = image.getPixel(point.first, point.second)
                            val color = PhotoTestImages.colors[expected[orientation - 1][index]]
                            assertTrue("orientation $orientation, quadrant $index", abs(Color.red(pixel) - Color.red(color)) < 25 && abs(Color.green(pixel) - Color.green(color)) < 25 && abs(Color.blue(pixel) - Color.blue(color)) < 25)
                        }
                    } finally {
                        image.recycle()
                    }
                } finally {
                    file.delete()
                }
            }
        } finally {
            source.recycle()
        }
    }

    @Test
    fun preparationPreservesDetailInTheChosenCropAndBoundsExportSize() {
        val pattern = PhotoTestImages.pattern(120, 80)
        val source = try {
            PhotoTestImages.encode(pattern)
        } finally {
            pattern.recycle()
        }
        val corner = PhotoPreparation.prepare(source, SquarePhotoCrop(0.0, 0.0, 2.0))
        val image = requireNotNull(BitmapFactory.decodeByteArray(corner.data, 0, corner.data.size))
        try {
            assertEquals(40, image.width)
            val color = image.getPixel(20, 20)
            assertTrue(Color.red(color) > 230 && Color.green(color) < 25 && Color.blue(color) < 25)
        } finally {
            image.recycle()
        }
        for ((width, height, noise, expectedSize) in listOf(ExportCase(2048, 1024, false, 512), ExportCase(48, 30, false, 30), ExportCase(512, 512, true, 512))) {
            val bitmap = PhotoTestImages.pattern(width, height, noise)
            val data = try {
                PhotoTestImages.encode(bitmap)
            } finally {
                bitmap.recycle()
            }
            val result = PhotoPreparation.prepare(data)
            val decoded = requireNotNull(BitmapFactory.decodeByteArray(result.data, 0, result.data.size))
            try {
                assertEquals(expectedSize, decoded.width)
                assertEquals(expectedSize, decoded.height)
                assertEquals(expectedSize, result.pixelSize)
                assertTrue(result.data.size <= 200 * 1024)
                assertArrayEquals(byteArrayOf(0xFF.toByte(), 0xD8.toByte()), result.data.take(2).toByteArray())
            } finally {
                decoded.recycle()
            }
        }
        assertThrows(IllegalArgumentException::class.java) { PhotoPreparation.prepare("invalid image".toByteArray()) }
    }

    private data class ExportCase(val width: Int, val height: Int, val noise: Boolean, val expectedSize: Int)
}
