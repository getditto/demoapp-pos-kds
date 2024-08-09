package live.ditto.ditto_wrapper.dittowrappers

import live.ditto.ditto_wrapper.DittoProperty
import live.ditto.ditto_wrapper.DittoPropertyDeserializer

interface DittoCollectionSubscription <T> {
    val collectionName: String
    val subscriptionQuery: String
    val subscriptionQueryArgs: Map<String, Any>
    val evictionQuery: String
    val deserializer: DittoPropertyDeserializer<T>
}