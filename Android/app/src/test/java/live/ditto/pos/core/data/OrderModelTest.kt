package live.ditto.pos.core.data

import kotlinx.serialization.json.Json
import live.ditto.pos.core.data.orders.Order
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.time.Instant

internal object OrderFixture {
    fun text(): String = checkNotNull(OrderModelTest::class.java.classLoader?.getResource("order.json")).readText()
    fun load(): Order = dittoJson.decodeFromString(text())
}

class OrderModelTest {
    // The order number shown on POS and KDS is the first 8 characters of the
    // ID in uppercase, so orders created on Android (lowercase UUIDs) and iOS
    // (uppercase UUIDs) look the same on every device.
    @Test
    fun `title is the first eight characters of the id in uppercase`() {
        fun order(id: String) = OrderFixture.load().copy(documentId = DocumentID(id, "42"))
        assertEquals("FE9B5646", order("fe9b5646-6319-4f20-b4e6-3ae2841e395e").title)
        assertEquals("D8161832", order("D8161832-0C3A-4E2B-9F4D-5A6B7C8D9E0F").title)
        assertEquals("AB12", order("ab12").title)
    }

    @Test
    fun `known fixture preserves composite identity maps quotes and unicode on the wire`() {
        val order = OrderFixture.load()
        assertEquals(DocumentID("order-'\"☕", "42"), order.documentId)
        assertEquals("Coffee \"冰\"", order.cart["line-1"]?.name)
        assertEquals(OrderStatus.IN_PROCESS, order.status)
        assertTrue(order.isPaid)
        assertEquals(Json.parseToJsonElement(OrderFixture.text()), Json.parseToJsonElement(order.dittoJsonString()))
    }

    @Test
    fun `totals count every unit and summary combines repeated names`() {
        val order = OrderFixture.load()
        assertEquals(1097, order.totalCents)
        assertEquals(mapOf("Coffee \"冰\"" to 5), order.summary)
        assertEquals(listOf(199, 250), order.sortedLineItems.map { it.price.amount })
    }

    @Test
    fun `adding repeated product lines preserves receipt payment and status history`() {
        val original = OrderFixture.load()
        val item = CartLineItem("coffee-冰", "New coffee", "coffee", Price(100), qty = 2)
        val updated = original.addingCartLineItem(item, "line-3")
        assertEquals(1297, updated.totalCents)
        assertEquals(original.cart["line-1"], updated.cart["line-1"])
        assertEquals(original.cart["line-2"], updated.cart["line-2"])
        assertEquals(original.payments, updated.payments)
        assertEquals(original.documentId, updated.documentId)
        assertEquals(original.createdAt, updated.createdAt)
        original.statusLog.forEach { (key, value) -> assertEquals(value, updated.statusLog[key]) }
        assertEquals(2, original.cart.size)
    }

    @Test
    fun `payment and status mutations preserve unrelated maps`() {
        val original = OrderFixture.load()
        val paid = original.addingPayment(Payment(PaymentType.DEBIT, Price(847)), "debit-2")
        assertEquals(2, paid.payments.size)
        assertEquals(original.payments["cash-1"], paid.payments["cash-1"])
        assertEquals(original.cart, paid.cart)
        assertEquals(original.statusLog, paid.statusLog)
        val changed = paid.appendingStatus(OrderStatus.PROCESSED, Instant.parse("2026-04-01T12:00:10.000Z"))
        assertEquals(OrderStatus.PROCESSED, changed.status)
        assertEquals(paid.cart, changed.cart)
        assertEquals(paid.payments, changed.payments)
        assertEquals(original.statusLog.size + 1, changed.statusLog.size)
    }

    @Test
    fun `zero dollar cart still needs a payment entry and canceled is terminal`() {
        val item = CartLineItem("free", "Free sample", "", Price(0), qty = 2)
        val order = Order.new("42").addingCartLineItem(item, "free-1")
        assertEquals(0, order.totalCents)
        assertFalse(order.isPaid)
        assertTrue(order.addingPayment(Payment(PaymentType.CASH, Price(0)), "zero").isPaid)
        assertTrue(order.appendingStatus(OrderStatus.CANCELED).isPaid)
    }

    @Test
    fun `line snapshot retains old catalog metadata after replacement`() {
        var catalog = SaleItem(DocumentID("coffee", "42"), "Original", "coffee", Price(199))
        val line = CartLineItem.from(catalog, qty = 3)
        catalog = catalog.copy(name = "Renamed", imageName = "tea", price = Price(999))
        assertEquals("Original", line.name)
        assertEquals(199, line.price.amount)
        assertEquals("coffee", line.imageName)
        assertEquals(3, line.qty)
        assertEquals(999, CartLineItem.from(catalog).price.amount)
    }
}
