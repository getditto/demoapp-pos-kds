package live.ditto.ditto_wrapper.dittowrappers

interface DittoCollectionSubscription {
    val collectionName: String
    val subscriptionQuery: String
    val subscriptionQueryArgs: Map<String, Any>
    val evictionQuery: String
}