package live.ditto.pos.core.data.images

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PhotoCropTest {
    @Test
    fun cropCoordinatesMatchSharedPanZoomAndBoundaryCases() {
        val data = requireNotNull(javaClass.classLoader?.getResourceAsStream("photo-crops.json")).bufferedReader().use { it.readText() }
        Json.parseToJsonElement(data).jsonArray.forEach {
            val item = it.jsonObject
            fun integer(key: String) = item.getValue(key).jsonPrimitive.int
            fun number(key: String) = item.getValue(key).jsonPrimitive.double
            val actual = SquarePhotoCrop(number("centerX"), number("centerY"), number("zoom")).rectangle(integer("width"), integer("height"))
            assertEquals(item.getValue("name").toString(), PhotoCropRectangle(integer("left"), integer("top"), integer("side")), actual)
        }
        listOf(SquarePhotoCrop(zoom = 0.5), SquarePhotoCrop(centerX = Double.NaN), SquarePhotoCrop(centerY = Double.POSITIVE_INFINITY), SquarePhotoCrop(zoom = 1000.0)).forEach {
            assertThrows(IllegalArgumentException::class.java) { it.rectangle(32, 48) }
        }
        assertThrows(IllegalArgumentException::class.java) { SquarePhotoCrop().rectangle(0, 32) }
    }
}
