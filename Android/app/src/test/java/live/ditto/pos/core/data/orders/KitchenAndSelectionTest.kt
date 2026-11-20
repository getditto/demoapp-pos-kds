package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.OrderFixture
import live.ditto.pos.core.data.OrderStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KitchenAndSelectionTest {
    @Test
    fun `only active kitchen stages can advance`() {
        assertEquals(OrderStatus.PROCESSED, KitchenOrders.nextStatus(OrderStatus.IN_PROCESS))
        assertEquals(OrderStatus.DELIVERED, KitchenOrders.nextStatus(OrderStatus.PROCESSED))
        for (status in listOf(OrderStatus.OPEN, OrderStatus.DELIVERED, OrderStatus.CANCELED)) {
            assertNull(KitchenOrders.nextStatus(status))
        }
    }

    @Test
    fun `saved order is reused only when present and in an existing reusable stage`() {
        val template = OrderFixture.load()
        val id = template.documentId.id
        val cases = listOf(
            OrderStatus.OPEN to id,
            OrderStatus.IN_PROCESS to id,
            OrderStatus.PROCESSED to null,
            OrderStatus.DELIVERED to null,
            OrderStatus.CANCELED to null
        )
        for ((stage, expected) in cases) {
            val observed = template.copy(statusLog = mapOf("2026-04-01T12:00:00.000Z" to stage.wireValue))
            assertEquals(stage.name, expected, OrderSelection.reusableOrderId(id, listOf(observed)))
        }
        assertNull(OrderSelection.reusableOrderId(id, emptyList()))
        assertNull(OrderSelection.reusableOrderId("another", listOf(template)))
        assertNull(OrderSelection.reusableOrderId("", listOf(template)))
    }
}
