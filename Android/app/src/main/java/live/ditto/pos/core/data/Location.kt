package live.ditto.pos.core.data

data class Location(
    val id: String,
    val name: String,
    val saleItemIds: Map<String, String> = emptyMap()
)
