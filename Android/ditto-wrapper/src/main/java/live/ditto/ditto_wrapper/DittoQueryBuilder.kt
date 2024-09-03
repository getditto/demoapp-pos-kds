package live.ditto.ditto_wrapper

class DittoQueryBuilder private constructor(
    val query: String,
    val arguments: Map<String, Any>?
){

}