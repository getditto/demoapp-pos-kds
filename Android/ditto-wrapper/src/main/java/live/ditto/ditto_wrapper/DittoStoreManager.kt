package live.ditto.ditto_wrapper

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.Ditto
import live.ditto.DittoSubscription
import live.ditto.DittoSyncSubscription

class DittoStoreManager(
    private val ditto: Ditto
) {

    private val subscriptions = mutableListOf<DittoSyncSubscription>()

    fun <T> subscribe(
        query: String,
        args: Map<String, Any> = emptyMap(),
        deserialize: (List<DittoProperty>) -> T
    ): Flow<T> {
        return subscribe(query, args)
            .map { documents ->
                deserialize(documents)
            }
    }

    private fun subscribe(
        subscriptionQuery: String,
        args: Map<String, Any> = emptyMap()
    ): Flow<List<DittoProperty>> {
        subscriptions.add(
            ditto.sync.registerSubscription(
                query = subscriptionQuery,
                arguments = args
            )
        )
        return ditto.store.registerObserverAsFlow(
            query = subscriptionQuery,
            params = args
        ).map { dittoQueryResult ->
            dittoQueryResult.items.map { dittoQueryResultItem ->
                dittoQueryResultItem.value
            }
        }
    }
}