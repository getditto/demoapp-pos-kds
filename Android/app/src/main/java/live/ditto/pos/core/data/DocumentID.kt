package live.ditto.pos.core.data

import kotlinx.serialization.Serializable

// Composite Ditto document `_id`. Shared by Order and SaleItem; same shape
// (a stable id within a location scope) lets sync subscriptions filter on
// `_id.locationId`.
@Serializable
data class DocumentID(
    val id: String,
    val locationId: String
)
