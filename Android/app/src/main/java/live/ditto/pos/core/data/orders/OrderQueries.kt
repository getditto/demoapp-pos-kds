package live.ditto.pos.core.data.orders

internal fun dqlIdentifier(value: String): String = "`${value.replace("`", "``")}`"

internal fun Order.cartPathsForUnset(): String = cart.keys.joinToString(", ") { "cart.${dqlIdentifier(it)}" }
