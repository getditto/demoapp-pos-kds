package live.ditto.ditto_wrapper.dittowrappers

import live.ditto.ditto_wrapper.DittoPropertyDeserializer

interface DittoLiveQuery <T> {

    val queryString: String
    val arguments: Map<String, Any>?
        get() = emptyMap()
    val documentDeserializer: DittoPropertyDeserializer<T>
}