package live.ditto.ditto_wrapper

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription
import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.ditto_wrapper.dittowrappers.DittoSelectQuery

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
        dittoQuery: DittoSelectQuery<T>,
    ): Flow<T> {
        val query = dittoQuery.queryString
        val args = dittoQuery.arguments
        val documentDeserializer = dittoQuery.documentDeserializer
        return liveQueryAsFlow(query, args)
            .map { documents ->
                documentDeserializer(documents)
            }
    }

    suspend fun executeQuery(dittoQuery: DittoQuery) {
        ditto.store.execute(
            query = dittoQuery.queryString,
            arguments = dittoQuery.arguments
        )
    }

    suspend fun <T> executeQuery(dittoSelectQuery: DittoSelectQuery<T>): Flow<T> {
        return flow {
            ditto.store.execute(
                query = dittoSelectQuery.queryString,
                arguments = dittoSelectQuery.arguments
            ).items.map { dittoQueryResultItem ->
                dittoQueryResultItem.value
            }
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