package live.ditto.pos.orders

import live.ditto.pos.core.data.orders.Order
import org.junit.Assert.assertEquals
import org.junit.Test

class OrderSummaryViewModelTest {
    @Test
    fun orderColumnsReflowForPhoneAndLargeTextThenReturnToWideLayout() {
        val widths = listOf(393f, 1200f, 1200f, 393f, 1200f)
        val fontScales = listOf(1f, 1f, 1.5f, 1.5f, 1f)
        val layouts = widths.zip(fontScales).map { (width, fontScale) ->
            OrderSummaryViewModel(Order.new("A"), width, fontScale).usesColumns
        }
        assertEquals(listOf(false, true, false, false, true), layouts)
    }
}
