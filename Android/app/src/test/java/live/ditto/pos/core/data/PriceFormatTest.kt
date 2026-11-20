package live.ditto.pos.core.data

import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Locale

// Prices are formatted in the price's own currency. The device locale only
// decides the layout (symbol position, separators), as on iOS.
class PriceFormatTest {
    private val originalLocale = Locale.getDefault()

    @After
    fun restoreLocale() = Locale.setDefault(originalLocale)

    @Test
    fun `dollar prices stay in dollars with cents on a Japanese device`() {
        assertEquals("$8.50", Price(850).formatted(Locale.JAPAN))
        assertEquals("$17.95", Price(1795).formatted(Locale.JAPAN))
        assertEquals("$0.00", Price(0).formatted(Locale.JAPAN))
    }

    @Test
    fun `dollar prices are unchanged on a US device`() {
        assertEquals("$8.50", Price(850).formatted(Locale.US))
        assertEquals("$1,234.50", Price(123450).formatted(Locale.US))
    }

    @Test
    fun `other currencies use their own symbol`() {
        assertEquals("€8.50", Price(850, Currency.EUR).formatted(Locale.US))
        assertEquals("£8.50", Price(850, Currency.GBP).formatted(Locale.US))
    }

    @Test
    fun `order lines use the device locale but the line's currency`() {
        Locale.setDefault(Locale.JAPAN)
        val line = CartLineItem("corn", "Corn", Price(350))
        assertEquals("$3.50", OrderItemUiModel.from(line).price)
    }
}
