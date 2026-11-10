package live.ditto.pos.core.data.images

import com.ditto.kotlin.DittoAttachment
import com.ditto.kotlin.DittoStore
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.DocumentID
import java.io.ByteArrayInputStream

object PhotoAttachments {
    suspend fun configure(store: DittoStore) {
        DittoManager.configureAttachmentFetching(store)
    }

    suspend fun importPhoto(data: ByteArray, mimeType: String, store: DittoStore): DittoAttachment =
        ByteArrayInputStream(data).use { store.newAttachment(it, mapOf("mime_type" to mimeType)) }

    fun reference(attachment: DittoAttachment): PhotoReference = PhotoReference(
        attachment.id,
        attachment.len,
        attachment.metadata.entries.associate { it.key.string to it.value.string }
    )

    // Attachments must cross the SDK binding directly, outside ordinary JSON encoding.
    // https://docs.ditto.live/sdk/latest/crud/working-with-attachments
    suspend fun replace(attachment: DittoAttachment, id: DocumentID, store: DittoStore) {
        store.execute(
            """
                UPDATE COLLECTION sale_items (image ATTACHMENT) SET image = :image
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf("image" to attachment, "id" to id.id, "locationId" to id.locationId)
        )
    }

    suspend fun remove(id: DocumentID, store: DittoStore) {
        store.execute(
            """
                UPDATE COLLECTION sale_items (image ATTACHMENT) UNSET image
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf("id" to id.id, "locationId" to id.locationId)
        )
    }
}
