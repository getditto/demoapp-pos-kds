package live.ditto.pos.core.data

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlin.time.Instant
import kotlin.time.toJavaInstant

// Shared UTC precision keeps stored dates chronologically sortable across platforms.
private val dittoIsoFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

fun Instant.toDittoIsoString(): String =
    dittoIsoFormatter.format(this.toJavaInstant())

object DittoInstantSerializer : KSerializer<Instant> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("live.ditto.pos.DittoInstant", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: Instant) {
        encoder.encodeString(value.toDittoIsoString())
    }

    override fun deserialize(decoder: Decoder): Instant =
        Instant.fromEpochMilliseconds(Instant.parse(decoder.decodeString()).toEpochMilliseconds())
}
