package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.OrderFixture
import live.ditto.pos.core.data.OrderStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import kotlin.time.Instant

class KitchenAndSelectionTest {
    @Test
    fun `kitchen groups stages newest first keeps unpaid and hides empty orders`() {
        val template = OrderFixture.load()
        fun order(id: String, stage: OrderStatus, seconds: Long, paid: Boolean = false) = template.copy(
            documentId = DocumentID(id, "42"),
            payments = if (paid) template.payments else emptyMap(),
            statusLog = mapOf("2026-04-01T12:00:00.000Z" to stage.wireValue),
            createdAt = Instant.fromEpochSeconds(seconds)
        )
        val orders = listOf(
            order("ready-new", OrderStatus.PROCESSED, 20, paid = true),
            order("preparing-old", OrderStatus.IN_PROCESS, 11),
            order("done", OrderStatus.DELIVERED, 30),
            order("ready-old", OrderStatus.PROCESSED, 10),
            order("preparing-new", OrderStatus.IN_PROCESS, 21),
            order("canceled", OrderStatus.CANCELED, 40),
            order("open", OrderStatus.OPEN, 50),
            order("empty", OrderStatus.IN_PROCESS, 60).copy(cart = emptyMap())
        )
        val selected = KitchenOrders.select(orders)
        assertEquals(listOf("preparing-new", "preparing-old", "ready-new", "ready-old"), selected.map { it.documentId.id })
        assertEquals(listOf(false, false, true, false), selected.map { it.isPaid })
        assertEquals(mapOf("Coffee \"冰\"" to 5), selected.first().summary)
    }

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
