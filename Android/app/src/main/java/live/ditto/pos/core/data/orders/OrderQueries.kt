package live.ditto.pos.core.data.orders

internal fun Order.cartPathsForUnset(): String = cart.keys.joinToString(", ") { "cart.`$it`" }
