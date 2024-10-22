package live.ditto.pos.core.data.locations.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.locations.Location

class InsertCustomLocationDittoQuery(
    private val customLocation: Location
) : DittoQuery {

    override val queryString: String
        get() = INSERT_CUSTOM_LOCATION_QUERY.trimIndent()
    override val arguments: Map<String, Any>
        get() = mapOf(
            "new" to customLocation.serializeAsMap()
        )
}
