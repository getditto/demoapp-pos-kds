package live.ditto.ditto_wrapper

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.Ditto

class DittoStoreManager(
    private val ditto: Ditto
) {

    fun subscribe(
        subscriptionQuery: String,
        args: Map<String, String> = emptyMap()
    ): Flow<List<DittoProperty>> {
        return ditto.store.registerObserverAsFlow(
            query = subscriptionQuery,
            params = args
        ).map { dittoQueryResult ->
            dittoQueryResult.items.map {
                it.value
            }
        }
    }
}