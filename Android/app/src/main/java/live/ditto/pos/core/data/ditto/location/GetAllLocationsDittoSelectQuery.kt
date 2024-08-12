package live.ditto.pos.core.data.ditto.location

import live.ditto.ditto_wrapper.DittoPropertyDeserializer
import live.ditto.ditto_wrapper.dittowrappers.DittoSelectQuery
import live.ditto.pos.core.data.Location
import live.ditto.pos.core.data.toLocation

class GetAllLocationsDittoSelectQuery : DittoSelectQuery<List<Location>> {

    override val documentDeserializer: DittoPropertyDeserializer<List<Location>>
        get() = { dittoProperties ->
            dittoProperties.map { it.toLocation() }
        }
    override val queryString = SELECT_ALL_LOCATIONS_QUERY
}