package live.ditto.pos.legacy

import com.ditto.kotlin.DittoStore
import live.ditto.pos.core.data.dittoJsonString

// Exact beab457 OrdersRepository.upsert statement with an offline test store.
internal suspend fun LegacyOrder.write(store: DittoStore) {
    store.execute(
        """
            INSERT INTO pos_orders
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
        """.trimIndent(),
        mapOf("json" to dittoJsonString())
    )
}
