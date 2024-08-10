package live.ditto.pos.core.data

import live.ditto.ditto_wrapper.DittoProperty
import live.ditto.ditto_wrapper.deserializeProperty

data class Location(
    val id: String,
    val name: String,
    val saleItemIds: Map<String, String> = emptyMap()
)

fun DittoProperty.toLocation(): Location {
    return Location(
        id = deserializeProperty("_id"),
        name = deserializeProperty("name"),
        saleItemIds = deserializeProperty("saleItemIds")
    )
}
