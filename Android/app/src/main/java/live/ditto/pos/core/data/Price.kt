package live.ditto.pos.core.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Whole-number minor units (cents for USD) avoids floating-point drift.
@Serializable
data class Price(
    val amount: Int,
    val currency: Currency = Currency.USD
) {
    val dollars: Double get() = amount / 100.0
}

@Serializable
enum class Currency {
    @SerialName("chf")
    CHF,

    @SerialName("eur")
    EUR,

    @SerialName("gbp")
    GBP,

    @SerialName("usd")
    USD
}
