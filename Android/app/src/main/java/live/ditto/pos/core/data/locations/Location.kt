package live.ditto.pos.core.data.locations

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Location(
    @SerialName("_id") val id: String,
    val name: String
) {
    companion object {
        const val COLLECTION_NAME = "locations"
    }
}
