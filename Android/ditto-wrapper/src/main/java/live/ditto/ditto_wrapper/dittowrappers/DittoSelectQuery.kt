package live.ditto.ditto_wrapper.dittowrappers

import live.ditto.ditto_wrapper.DittoPropertyDeserializer

interface DittoSelectQuery<T>: DittoQuery {

    val documentDeserializer: DittoPropertyDeserializer<T>

}