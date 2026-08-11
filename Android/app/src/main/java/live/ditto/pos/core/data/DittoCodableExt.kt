package live.ditto.pos.core.data

import com.ditto.kotlin.DittoQueryResult
import com.ditto.kotlin.DittoQueryResultItem
import com.ditto.kotlin.DittoStore
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString

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
 * `store.observe` returns a cold Flow whose suspending `transform` provides
 * natural backpressure: Ditto delivers the next result only after the previous
 * `transform` completes. The query result is auto-closed once `transform`
 * returns; each item's `dematerialize()` runs inside `decode()` via try/finally.
 */
inline fun <reified T> DittoStore.observeAsFlow(
    query: String,
    args: Map<String, Any> = emptyMap()
): Flow<List<T>> = observe(query, args) { result ->
    result.decodeOrSkip<T>()
}
