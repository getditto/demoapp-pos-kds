package live.ditto.ditto_wrapper.dittowrappers

interface DittoCollectionSubscription <T> {
    val collectionName: String
    val subscriptionQuery: String
    val subscriptionQueryArgs: Map<String, Any>
    val evictionQuery: String
}