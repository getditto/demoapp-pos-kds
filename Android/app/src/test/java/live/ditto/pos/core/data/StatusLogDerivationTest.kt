package live.ditto.pos.core.data

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.time.Instant

class StatusLogDerivationTest {

    @Test
    fun `empty or unknown legacy log uses requested fallback`() {
        for (log in listOf(emptyMap(), mapOf("2026-04-01T00:00:00.000Z" to "unknown-legacy-state"))) {
            assertEquals(OrderStatus.OPEN, StatusLogDerivation.currentStatus(log))
            assertEquals(OrderStatus.IN_PROCESS, StatusLogDerivation.currentStatus(log, OrderStatus.IN_PROCESS))
        }
    }

    @Test
    fun `most-advanced rank wins`() {
        val log = mapOf(
            "2026-04-01T00:00:00.000Z" to "open",
            "2026-04-01T00:00:01.000Z" to "inProcess",
            "2026-04-01T00:00:02.000Z" to "processed"
        )
        assertEquals(OrderStatus.PROCESSED, StatusLogDerivation.currentStatus(log))
    }

    @Test
    fun `newer lower status cannot regress an advanced state`() {
        val log = mapOf(
            "2026-04-01T00:00:00.500Z" to "delivered",
            "2026-04-01T00:00:02.000Z" to "open"
        )
        assertEquals(OrderStatus.DELIVERED, StatusLogDerivation.currentStatus(log))
    }

    @Test
    fun `canceled is terminal even if rank-100 entry is older`() {
        val log = mapOf(
            "2026-04-01T00:00:01.000Z" to "canceled",
            "2026-04-01T00:00:02.000Z" to "delivered"
        )
        assertEquals(OrderStatus.CANCELED, StatusLogDerivation.currentStatus(log))
    }

    @Test
    fun `entry returns wire value paired with timestamp in canonical ditto format`() {
        val instant = Instant.parse("2026-04-01T12:00:00.000Z")
        val (ts, value) = StatusLogDerivation.entry(OrderStatus.PROCESSED, at = instant)
        assertEquals("2026-04-01T12:00:00.000Z", ts)
        assertEquals("processed", value)
    }
}
