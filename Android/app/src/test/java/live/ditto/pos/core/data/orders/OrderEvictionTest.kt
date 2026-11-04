package live.ditto.pos.core.data.orders

import kotlinx.coroutines.runBlocking
import kotlinx.datetime.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import kotlin.time.Instant

class OrderEvictionTest {
    @Test
    fun `elapsed 24 hour boundary and successful checkpoint suppress repeated eviction`() = runBlocking {
        var instant = Instant.fromEpochSeconds(86_399)
        var last = 0L
        val cutoffs = mutableListOf<String>()
        val eviction = OrderEviction(
            now = { instant },
            timeZone = TimeZone.UTC,
            lastRun = { last },
            recordRun = { last = it },
            evict = { cutoffs += it }
        )
        assertNull(eviction.runIfDue())
        assertTrue(cutoffs.isEmpty())
        instant = Instant.fromEpochSeconds(86_400)
        assertEquals("1970-01-02T00:00:00.000Z", eviction.runIfDue())
        assertEquals(86_400_000L, last)
        assertNull(eviction.runIfDue())
        assertEquals(1, cutoffs.size)
    }

    @Test
    fun `failure retains checkpoint and retry uses local midnight across daylight saving`() = runBlocking {
        val instant = Instant.parse("2026-11-02T04:30:00.000Z")
        var last = 0L
        var attempts = 0
        val eviction = OrderEviction(
            now = { instant },
            timeZone = TimeZone.of("America/New_York"),
            lastRun = { last },
            recordRun = { last = it },
            evict = {
                attempts++
                assertEquals("2026-11-01T04:00:00.000Z", it)
                if (attempts == 1) error("Injected storage failure")
            }
        )
        try {
            eviction.runIfDue()
            fail("Expected storage failure")
        } catch (_: IllegalStateException) { }
        assertEquals(0L, last)
        eviction.runIfDue()
        assertEquals(2, attempts)
        assertEquals(instant.toEpochMilliseconds(), last)
    }
}
