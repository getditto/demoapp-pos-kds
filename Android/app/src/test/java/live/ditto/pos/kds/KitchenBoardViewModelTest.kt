package live.ditto.pos.kds

import live.ditto.pos.core.data.OrderStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.time.Instant

class KitchenBoardViewModelTest {
    @Test
    fun observedTicketPartitionsPreserveOrderAndOnlyPartiallyEmptyWideBoardsUseWells() {
        val ready = ticket("ready-new", OrderStatus.PROCESSED)
        val preparing = ticket("preparing-new", OrderStatus.IN_PROCESS)
        val older = ticket("preparing-old", OrderStatus.IN_PROCESS)
        val phone = KitchenBoardViewModel(listOf(ready, preparing, older), 393f)
        assertEquals(listOf("preparing-new", "preparing-old", "ready-new"), phone.phoneTickets.map { it.orderId })
        assertFalse(phone.showPreparingWell)
        assertFalse(phone.showReadyWell)

        val wide = KitchenBoardViewModel(listOf(ready), 1200f)
        assertTrue(wide.showPreparingWell)
        assertFalse(wide.showReadyWell)
        val advanced = KitchenBoardViewModel(listOf(ready, preparing.copy(orderStatus = OrderStatus.PROCESSED)), 1200f)
        assertEquals(2, advanced.ready.size)
        assertTrue(advanced.showPreparingWell)
        val empty = KitchenBoardViewModel(emptyList(), 1200f)
        assertTrue(empty.isEmpty)
        assertFalse(empty.showPreparingWell)
        assertFalse(empty.showReadyWell)
    }

    private fun ticket(id: String, status: OrderStatus) = TicketItemUi(
        Instant.parse("2026-11-12T12:00:00Z"),
        id,
        hashMapOf("Burger" to 2),
        false,
        status,
        id
    )
}
