package live.ditto.pos.core.data

import com.ditto.kotlin.DittoQueryResult
import com.ditto.kotlin.DittoQueryResultItem
import com.ditto.kotlin.DittoStore
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString

inline fun <reified T> T.dittoJsonString(): String = dittoJson.encodeToString(this)

// Materialized query items retain native memory.
inline fun <reified T> DittoQueryResultItem.decode(): T = try {
    dittoJson.decodeFromString<T>(jsonString())
} finally {
    dematerialize()
}

inline fun <reified T> DittoQueryResult.decode(): List<T> = items.map { it.decode<T>() }

// One incomplete document must not hide the rest of the observed catalog/orders.
inline fun <reified T> DittoQueryResult.decodeOrSkip(): List<T> =
    items.mapNotNull { runCatching { it.decode<T>() }.getOrNull() }

inline fun <reified T> DittoStore.observeAsFlow(
    query: String,
    args: Map<String, Any> = emptyMap()
): Flow<List<T>> = observe(query, args) { result ->
    result.decodeOrSkip<T>()
}
