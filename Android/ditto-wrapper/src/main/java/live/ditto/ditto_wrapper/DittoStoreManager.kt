package live.ditto.ditto_wrapper

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription

class DittoStoreManager(
    private val ditto: Ditto
) {

    /**
     * Map of collection name to [DittoSyncSubscription]
     */
    private val currentSubscriptions: MutableMap<String, DittoSyncSubscription> = mutableMapOf()

    fun <T> startSubscription(
        dittoCollectionSubscription: DittoCollectionSubscription<T>
    ): Flow<T> {
        registerSubscription(dittoCollectionSubscription)
        return subscribe(
            query = dittoCollectionSubscription.subscriptionQuery,
            args = dittoCollectionSubscription.subscriptionQueryArgs,
            deserialize = dittoCollectionSubscription.deserializer
        )
    }

    private fun <T> registerSubscription(dittoCollectionSubscription: DittoCollectionSubscription<T>) {
        val dittoSyncSubscription = ditto.sync.registerSubscription(
            query = dittoCollectionSubscription.subscriptionQuery,
            arguments = dittoCollectionSubscription.subscriptionQueryArgs
        )
        currentSubscriptions[dittoCollectionSubscription.collectionName] = dittoSyncSubscription
    }

    private fun <T> subscribe(
        query: String,
        args: Map<String, Any> = emptyMap(),
        deserialize: DittoPropertyDeserializer<T>
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