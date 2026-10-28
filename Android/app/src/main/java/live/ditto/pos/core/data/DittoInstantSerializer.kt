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

// Wire-compatible with iOS `DittoWireDate`: always millisecond precision
// with trailing `Z` (UTC). Important because DQL filters/sorts on these
// timestamps as strings (e.g. `WHERE createdAt > :TTL`), and lexicographic
// comparison only matches chronological order if every timestamp uses the
// same precision and zone format.
//
// The default `Instant` serializer uses `Instant.toString()`, whose number of
// fractional digits varies with the value and would violate that invariant.
private val dittoIsoFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

/** Canonical ditto-wire string, for DQL parameters and map keys. */
fun Instant.toDittoIsoString(): String =
    dittoIsoFormatter.format(this.toJavaInstant())

object DittoInstantSerializer : KSerializer<Instant> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("live.ditto.pos.DittoInstant", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: Instant) {
        encoder.encodeString(value.toDittoIsoString())
    }

    override fun deserialize(decoder: Decoder): Instant =
        Instant.parse(decoder.decodeString())
}
