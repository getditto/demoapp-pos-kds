package live.ditto.pos.core.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.text.NumberFormat
import java.util.Locale

// Whole-number minor units (cents for USD) avoids floating-point drift.
@Serializable
data class Price(
    val amount: Int,
    val currency: Currency = Currency.USD
) {
    val dollars: Double get() = amount / 100.0

    // Format in this price's currency. The locale only decides the layout
    // (symbol position, separators), so a Japanese device still shows "$8.50"
    // instead of converting the symbol to yen and dropping the cents.
    fun formatted(locale: Locale = Locale.getDefault()): String {
        val format = NumberFormat.getCurrencyInstance(locale)
        format.currency = java.util.Currency.getInstance(currency.name)
        format.minimumFractionDigits = 2
        format.maximumFractionDigits = 2
        return format.format(dollars)
    }
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
