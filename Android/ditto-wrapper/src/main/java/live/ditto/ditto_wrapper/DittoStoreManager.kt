package live.ditto.ditto_wrapper

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription
import live.ditto.ditto_wrapper.dittowrappers.DittoLiveQuery

class DittoStoreManager(
    private val ditto: Ditto
) {

    /**
     * Map of collection name to [DittoSyncSubscription]
     */
    private val currentSubscriptions: MutableMap<String, DittoSyncSubscription> = mutableMapOf()

    fun <T> registerSubscription(dittoCollectionSubscription: DittoCollectionSubscription<T>) {
        val dittoSyncSubscription = ditto.sync.registerSubscription(
            query = dittoCollectionSubscription.subscriptionQuery,
            arguments = dittoCollectionSubscription.subscriptionQueryArgs
        )
        currentSubscriptions[dittoCollectionSubscription.collectionName] = dittoSyncSubscription
    }

    fun <T> observeLiveQueryAsFlow(
        dittoLiveQuery: DittoLiveQuery<T>,
    ): Flow<T> {
        val query = dittoLiveQuery.queryString
        val args = dittoLiveQuery.arguments ?: emptyMap()
        val documentDeserializer = dittoLiveQuery.documentDeserializer
        return liveQueryAsFlow(query, args)
            .map { documents ->
                documentDeserializer(documents)
            }
    }

    private fun liveQueryAsFlow(
        subscriptionQuery: String,
        args: Map<String, Any> = emptyMap()
    ): Flow<List<DittoProperty>> {
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