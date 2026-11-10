package live.ditto.pos.core.data.images

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.media.ExifInterface
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

data class SquarePhotoCrop(val centerX: Double = 0.5, val centerY: Double = 0.5, val zoom: Double = 1.0) {
    fun rectangle(width: Int, height: Int): PhotoCropRectangle {
        require(width > 0 && height > 0 && centerX.isFinite() && centerY.isFinite() && zoom.isFinite() && zoom >= 1) { "Invalid crop" }
        val side = floor(min(width, height) / zoom).toInt()
        require(side >= 1) { "Crop is smaller than one pixel" }
        val left = floor((centerX * width - side / 2.0).coerceIn(0.0, (width - side).toDouble())).toInt()
        val top = floor((centerY * height - side / 2.0).coerceIn(0.0, (height - side).toDouble())).toInt()
        return PhotoCropRectangle(left, top, side)
    }
}

data class PhotoCropRectangle(val left: Int, val top: Int, val side: Int)
data class PreparedPhoto(val data: ByteArray, val pixelSize: Int, val mimeType: String = "image/jpeg")

object PhotoPreparation {
    fun prepare(data: ByteArray, crop: SquarePhotoCrop = SquarePhotoCrop()): PreparedPhoto {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0) { "Unreadable image" }
        crop.rectangle(bounds.outWidth, bounds.outHeight)
        val desiredScale = min(1.0, 512 * crop.zoom / min(bounds.outWidth, bounds.outHeight))
        val requiredDimension = ceil(max(bounds.outWidth, bounds.outHeight) * desiredScale).toInt()
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= requiredDimension) sample *= 2
        val decoded = requireNotNull(BitmapFactory.decodeByteArray(data, 0, data.size, BitmapFactory.Options().apply { inSampleSize = sample })) { "Unreadable image" }
        try {
            val orientation = ByteArrayInputStream(data).use { ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL) }
            val matrix = orientationMatrix(orientation)
            val oriented = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
            try {
                val rect = crop.rectangle(oriented.width, oriented.height)
                val square = Bitmap.createBitmap(oriented, rect.left, rect.top, rect.side, rect.side)
                try {
                    val size = min(512, square.width)
                    val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                    try {
                        Canvas(output).apply {
                            drawColor(Color.WHITE)
                            drawBitmap(square, null, android.graphics.Rect(0, 0, size, size), Paint(Paint.FILTER_BITMAP_FLAG))
                        }
                        for (quality in 90 downTo 10 step 5) {
                            val stream = ByteArrayOutputStream()
                            check(output.compress(Bitmap.CompressFormat.JPEG, quality, stream)) { "Could not encode image" }
                            if (stream.size() <= 200 * 1024) return PreparedPhoto(stream.toByteArray(), size)
                        }
                        error("Prepared image exceeds the file size limit")
                    } finally {
                        output.recycle()
                    }
                } finally {
                    if (square !== oriented && square !== decoded) square.recycle()
                }
            } finally {
                if (oriented !== decoded) oriented.recycle()
            }
        } finally {
            decoded.recycle()
        }
    }

    private fun orientationMatrix(orientation: Int): Matrix = Matrix().apply {
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                setRotate(90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                setRotate(-90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> setRotate(-90f)
        }
    }
}
