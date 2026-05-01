package live.ditto.pos.core.data

import kotlinx.datetime.Clock
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Order status modeled as a timestamp-keyed audit log instead of a single
// LWW field. Every transition is preserved (Ditto's add-wins map merge);
// the "current" status is *derived* at read time using "most-advanced state
// wins." A stale device coming online late and writing an older state cannot
// regress the order's status — the older entry stays in the log for
// auditability but the read-time derivation ignores it.
//
// See: https://docs.ditto.live/best-practices/conflict-resolution-patterns
@Serializable
enum class OrderStatus {
    @SerialName("open")
    OPEN,

    @SerialName("inProcess")
    IN_PROCESS,

    @SerialName("processed")
    PROCESSED,

    @SerialName("delivered")
    DELIVERED,

    @SerialName("canceled")
    CANCELED;

    // Higher = more advanced. CANCELED is terminal.
    val rank: Int
        get() = when (this) {
            OPEN -> 0
            IN_PROCESS -> 1
            PROCESSED -> 2
            DELIVERED -> 3
            CANCELED -> 100
        }

    val wireValue: String
        get() = when (this) {
            OPEN -> "open"
            IN_PROCESS -> "inProcess"
            PROCESSED -> "processed"
            DELIVERED -> "delivered"
            CANCELED -> "canceled"
        }

    val next: OrderStatus?
        get() = when (this) {
            OPEN -> IN_PROCESS
            IN_PROCESS -> PROCESSED
            PROCESSED -> DELIVERED
            DELIVERED -> null
            CANCELED -> null
        }

    companion object {
        fun fromWire(value: String): OrderStatus? = entries.find { it.wireValue == value }
    }
}

object StatusLogDerivation {
    fun currentStatus(
        log: Map<String, String>,
        default: OrderStatus = OrderStatus.OPEN
    ): OrderStatus {
        if (log.isEmpty()) return default

        val entries = log.mapNotNull { (timestamp, raw) ->
            OrderStatus.fromWire(raw)?.let { timestamp to it }
        }
        if (entries.isEmpty()) return default

        if (entries.any { it.second == OrderStatus.CANCELED }) return OrderStatus.CANCELED

        val maxRank = entries.maxOf { it.second.rank }
        return entries.filter { it.second.rank == maxRank }.maxByOrNull { it.first }!!.second
    }

    /** (timestamp, status wire value) pair for a single new transition. */
    fun entry(status: OrderStatus, at: String = isoNow()): Pair<String, String> =
        at to status.wireValue
}

fun isoNow(): String = Clock.System.now().toString()
