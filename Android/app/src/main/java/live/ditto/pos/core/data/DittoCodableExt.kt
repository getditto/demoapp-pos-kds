package live.ditto.pos.core.data

import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.channels.trySendBlocking
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.serialization.encodeToString
import live.ditto.DittoQueryResult
import live.ditto.DittoQueryResultItem
import live.ditto.DittoStore

// JSON encoding / decoding helpers for @Serializable models. Push values into
// DQL via `deserialize_json(:json)` and read them back from `jsonString()`.
// Surgical UPDATEs (UNSET, SET on a specific field) still need raw DQL because
// they aren't whole-document operations.

inline fun <reified T> T.dittoJsonString(): String = dittoJson.encodeToString(this)

/**
 * Decode an item and release its materialized memory. Always call
 * `dematerialize()` after extracting data — this is the Ditto-recommended
 * hot-path cleanup. The `try/finally` mirrors Swift's `defer` and runs even
 * on decode errors.
 */
inline fun <reified T> DittoQueryResultItem.decode(): T = try {
    dittoJson.decodeFromString<T>(jsonString())
} finally {
    dematerialize()
}

/** Decodes every item; throws on any failure. Use when you need all-or-nothing. */
inline fun <reified T> DittoQueryResult.decode(): List<T> = items.map { it.decode<T>() }

/**
 * Decodes every item, silently dropping any that fail. Use for observers
 * where one bad document shouldn't blank the rest.
 */
inline fun <reified T> DittoQueryResult.decodeOrSkip(): List<T> =
    items.mapNotNull { runCatching { it.decode<T>() }.getOrNull() }

/**
 * Observe a DQL query as a Flow of decoded models, skipping any that fail to decode.
 *
 * Uses Ditto's `signalNext` overload of `registerObserver` for backpressure:
 * `signalNext()` is called only after the value has been sent into the channel.
 * With the default rendezvous channel that means Ditto won't deliver the next
 * update until our consumer has actually taken this one.
 */
inline fun <reified T> DittoStore.observeAsFlow(
    query: String,
    args: Map<String, Any> = emptyMap()
): Flow<List<T>> = callbackFlow {
    val observer = registerObserver(query, args) { result, signalNext ->
        // Decode first; signalNext only after the consumer has the decoded
        // payload so Ditto's next delivery is gated on us having actually
        // finished this one.
        // .use { } closes the result handle after decoding; each item's
        // dematerialize() is run inside decode() via try/finally.
        result.use { trySendBlocking(it.decodeOrSkip<T>()) }
        signalNext()
    }
    awaitClose { observer.close() }
}
