package live.ditto.ditto_wrapper

typealias DittoProperty = Map<String, Any>

class MissingPropertyException(collectionKey: String, dittoProperty: DittoProperty): Exception("Missing property: $collectionKey from DittoProperty:\n $dittoProperty")

/**
 * Deserialize a [DittoProperty] as the given type [T]
 * [collectionKey] the name of the collection key
 * @throws [MissingPropertyException] if the property is missing
 */
@Suppress("UNCHECKED_CAST")
fun <T> DittoProperty.deserializeProperty(collectionKey: String): T {
    val value = get(collectionKey) as? T
    return value ?: throw MissingPropertyException(collectionKey, this)
}

/**
 * Deserialize a [DittoProperty] as a [Map] of the specified [Key], [Value]
 * [collectionKey] the name of the collection key
 * [block] Provide a function that describes how to convert a [DittoProperty] into a [Value]
 */
@Suppress("UNCHECKED_CAST")
fun <Key, Value> DittoProperty.deserializeMap(
    collectionKey: String,
    block: (DittoProperty) -> Value
): Map<Key, Value> {
    val map = deserializeProperty<Map<*, *>>(collectionKey)
    val mutableMap = mutableMapOf<Key, Value>()
    map.entries.forEach {
        mutableMap[it.key as Key] = block(it.value as DittoProperty)
    }
    return mutableMap.toMap()
}
