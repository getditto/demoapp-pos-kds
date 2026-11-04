package live.ditto.pos.core.data.orders

import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import live.ditto.pos.core.data.toDittoIsoString
import kotlin.time.Instant

internal class OrderEviction(
    private val now: () -> Instant,
    private val timeZone: TimeZone,
    private val lastRun: () -> Long,
    private val recordRun: (Long) -> Unit,
    private val evict: suspend (String) -> Unit
) {
    suspend fun runIfDue(): String? {
        val instant = now()
        if (instant.toEpochMilliseconds() - lastRun() < 24L * 60 * 60 * 1000) return null
        val cutoff = instant.toLocalDateTime(timeZone).date.atStartOfDayIn(timeZone).toDittoIsoString()
        evict(cutoff)
        // A failed eviction must remain eligible on the next invocation.
        recordRun(instant.toEpochMilliseconds())
        return cutoff
    }
}
