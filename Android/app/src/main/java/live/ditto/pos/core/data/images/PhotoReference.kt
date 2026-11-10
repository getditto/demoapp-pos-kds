package live.ditto.pos.core.data.images

import kotlinx.serialization.Serializable

@Serializable
data class PhotoReference(val id: String, val len: ULong, val metadata: Map<String, String>) {
    fun token(): Map<String, Any> {
        // The SDK 5.2 map-based fetch API requires a boxed Int for the byte length.
        require(len <= Int.MAX_VALUE.toULong()) { "Photo exceeds the attachment token API's size limit" }
        return mapOf("id" to id, "len" to len.toInt(), "metadata" to metadata)
    }
}
