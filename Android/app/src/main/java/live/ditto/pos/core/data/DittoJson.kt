package live.ditto.pos.core.data

import kotlinx.serialization.json.Json

val dittoJson = Json {
    encodeDefaults = true
    ignoreUnknownKeys = true
}
