package live.ditto.pos.core.data

import kotlinx.serialization.Serializable
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import kotlin.time.Instant

class DittoInstantSerializerTest {
    @Serializable
    private data class Fixtures(val decoding: List<Decoding>, val encoding: List<Encoding>, val invalid: List<String>) {
        @Serializable
        data class Decoding(val input: String, val canonical: String, val epochMillis: Long)

        @Serializable
        data class Encoding(val epochSeconds: Long, val nanoseconds: Int, val canonical: String)
    }

    private fun fixtures(): Fixtures =
        checkNotNull(javaClass.classLoader?.getResource("wire-dates.json")).readText().let { dittoJson.decodeFromString(it) }

    @Test
    fun `supported inputs decode to UTC milliseconds`() {
        for (example in fixtures().decoding) {
            val instant = dittoJson.decodeFromString(DittoInstantSerializer, dittoJson.encodeToString(example.input))
            assertEquals(example.input, Instant.fromEpochMilliseconds(example.epochMillis), instant)
            assertEquals(example.input, dittoJson.encodeToString(example.canonical), dittoJson.encodeToString(DittoInstantSerializer, instant))
        }
    }

    @Test
    fun `encoding truncates sub-milliseconds without advancing the second`() {
        for (example in fixtures().encoding) {
            val instant = Instant.fromEpochSeconds(example.epochSeconds, example.nanoseconds.toLong())
            assertEquals(dittoJson.encodeToString(example.canonical), dittoJson.encodeToString(DittoInstantSerializer, instant))
        }
    }

    @Test
    fun `invalid inputs are rejected`() {
        for (input in fixtures().invalid) {
            assertThrows(input, IllegalArgumentException::class.java) {
                dittoJson.decodeFromString(DittoInstantSerializer, dittoJson.encodeToString(input))
            }
        }
    }
}
