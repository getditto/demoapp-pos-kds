package live.ditto.pos.core.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import kotlin.time.Instant

class DittoInstantSerializerTest {
    @Test
    fun `timestamps use UTC and millisecond precision in JSON`() {
        val examples =
            listOf(
                "2026-04-01T12:00:00Z" to "2026-04-01T12:00:00.000Z",
                "2026-04-01T12:00:00.123Z" to "2026-04-01T12:00:00.123Z",
                "2026-04-01T14:00:00.123+02:00" to "2026-04-01T12:00:00.123Z"
            )
        for ((input, expected) in examples) {
            val instant = Instant.parse(input)
            val json = dittoJson.encodeToString(DittoInstantSerializer, instant)
            assertEquals("\"$expected\"", json)
            assertEquals(instant, dittoJson.decodeFromString(DittoInstantSerializer, json))
        }
    }

    @Test
    fun `invalid timestamp is rejected`() {
        assertThrows(IllegalArgumentException::class.java) {
            dittoJson.decodeFromString(DittoInstantSerializer, "\"invalid\"")
        }
    }
}
