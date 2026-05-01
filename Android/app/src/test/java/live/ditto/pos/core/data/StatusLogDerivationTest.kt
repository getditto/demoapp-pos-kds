package live.ditto.pos.core.data

import org.junit.Assert.assertEquals
import org.junit.Test

class StatusLogDerivationTest {

    @Test
    fun `empty log returns the default`() {
        assertEquals(OrderStatus.OPEN, StatusLogDerivation.currentStatus(emptyMap()))
    }

    @Test
    fun `default override is honored when log is empty`() {
        assertEquals(
            OrderStatus.IN_PROCESS,
            StatusLogDerivation.currentStatus(emptyMap(), default = OrderStatus.IN_PROCESS)
        )
    }

    @Test
    fun `unparseable entries are ignored and default is returned`() {
        val log = mapOf("2026-04-01T00:00:00.000Z" to "garbage")
        assertEquals(OrderStatus.OPEN, StatusLogDerivation.currentStatus(log))
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
    fun `older write cannot regress to a less-advanced state`() {
        val log = mapOf(
            "2026-04-01T00:00:02.000Z" to "delivered",
            // Stale device coming online late writes an older OPEN entry —
            // older entry stays in the log for audit but does not regress.
            "2026-04-01T00:00:00.500Z" to "open"
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
    fun `tie at top rank breaks by latest timestamp`() {
        // Two PROCESSED entries — the later timestamp is the surviving one.
        val log = mapOf(
            "2026-04-01T00:00:01.000Z" to "processed",
            "2026-04-01T00:00:02.000Z" to "processed"
        )
        assertEquals(OrderStatus.PROCESSED, StatusLogDerivation.currentStatus(log))
    }

    @Test
    fun `entry returns wire value paired with timestamp`() {
        val (ts, value) = StatusLogDerivation.entry(OrderStatus.PROCESSED, at = "2026-04-01T12:00:00.000Z")
        assertEquals("2026-04-01T12:00:00.000Z", ts)
        assertEquals("processed", value)
    }
}
