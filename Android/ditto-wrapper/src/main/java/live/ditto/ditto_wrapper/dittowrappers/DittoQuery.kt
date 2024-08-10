package live.ditto.ditto_wrapper.dittowrappers

interface DittoQuery {

    val queryString: String
    val arguments: Map<String, Any>
        get() = emptyMap()
}