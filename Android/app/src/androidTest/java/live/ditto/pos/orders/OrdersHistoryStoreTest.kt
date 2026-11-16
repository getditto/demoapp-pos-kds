package live.ditto.pos.orders

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.data.images.PhotoAttachments
import live.ditto.pos.core.data.images.PhotoTestImages
import live.ditto.pos.core.data.orders.OrdersHistory
import live.ditto.pos.core.data.orders.OrdersHistoryState
import live.ditto.pos.legacy.LegacyCartLineItem
import live.ditto.pos.legacy.LegacyOrder
import live.ditto.pos.legacy.write
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.time.Instant

class OrdersHistoryStoreTest {
    @Test
    fun historyPreparesALegacyOrderArrivingAfterObservationStarts() = runBlocking {
        TestDitto.withInstance {
            val repository = repository()
            withContext(Dispatchers.Main) {
                val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
                val history = OrdersHistory(scope, repository::observeHistoryPage, repository::observeHistoryCount)
                try {
                    history.setLocation("00001")
                    history.setVisible(true)
                    history.await { total == 0 && orders.isEmpty() }

                    val legacyLine = LegacyCartLineItem("00001", "Historical burger", "milk", Price(100), qty = 2)
                    val legacyOrder = LegacyOrder.new("00001").addingCartLineItem(legacyLine, "burger-line")
                    legacyOrder.write(ditto.store)
                    PhotoAttachments.importPhoto(PhotoTestImages.stockPhoto, "image/png", ditto.store).use { bundledAttachment ->
                        history.await { total == 1 && orders.firstOrNull()?.cart?.get("burger-line")?.image?.id == bundledAttachment.id }
                    }
                    val preparedLine = history.state.value.orders.single().cart.getValue("burger-line")
                    assertEquals(legacyLine.name, preparedLine.name)
                    assertEquals(legacyLine.price, preparedLine.price)
                    assertEquals(legacyLine.qty, preparedLine.qty)
                } finally {
                    history.setVisible(false)
                    scope.cancel()
                }
            }
        }
    }

    @Test
    fun localPagesExcludeOtherLocationsAndEmptyCartsAndRepageAfterCleanup() = runBlocking {
        TestDitto.withInstance {
            val repository = repository(now = Instant.parse("2026-04-02T12:00:00Z"))
            val template = TestDitto.fixture()
            val old = Instant.parse("2026-03-31T12:00:00Z")
            val today = Instant.parse("2026-04-02T12:00:00Z")
            fun order(index: Int, location: String = "A", empty: Boolean = false) = template.copy(
                documentId = DocumentID("%08d".format(index), location),
                cart = if (empty) emptyMap() else template.cart.mapValues { (_, line) -> if (index == 0) line.copy(price = Price(0)) else line },
                payments = if (index % 2 == 0) template.payments else emptyMap(),
                createdAt = if (index < 50) old else today
            )
            repeat(105) { insert(order(it, "B")) }
            (200..254).forEach { insert(order(it, empty = true)) }
            withContext(Dispatchers.Main) {
                val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
                val history = OrdersHistory(scope, repository::observeHistoryPage, repository::observeHistoryCount)
                try {
                    history.setLocation("A")
                    history.setVisible(true)
                    history.await { total == 0 && orders.isEmpty() }
                    var inserted = 0
                    for (total in listOf(49, 50, 51, 100, 101)) {
                        (inserted until total).forEach { insert(order(it)) }
                        inserted = total
                        history.await { this.total == total && orders.size == minOf(50, total) }
                        assertEquals(
                            if (total <= 50) {
                                1
                            } else if (total <= 100) {
                                2
                            } else {
                                3
                            },
                            history.state.value.totalPages
                        )
                        assertTrue(history.state.value.orders.all { it.documentId.locationId == "A" && it.cart.isNotEmpty() })
                    }
                    history.next()
                    history.await { pageIndex == 1 && orders.size == 50 }
                    history.next()
                    history.await { pageIndex == 2 && orders.map { it.documentId.id } == listOf("00000049") }
                    assertFalse(history.state.value.canNext)
                    assertEquals(old, history.state.value.orders.single().createdAt)
                    ditto.store.execute("DELETE FROM pos_orders WHERE _id.locationId = :locationId AND _id.id = :id", mapOf("locationId" to "A", "id" to "00000049"))
                    history.await { total == 100 && pageIndex == 1 && orders.size == 50 }
                    insert(order(101))
                    history.await { total == 101 && pageIndex == 1 && canNext }
                    repository.upsert(order(200))
                    history.await { total == 102 }
                    repository.clearCart(order(200))
                    history.await { total == 101 }
                    history.previous()
                    history.await { pageIndex == 0 && orders.size == 50 }
                    assertEquals(listOf("00000050", "00000051", "00000052"), history.state.value.orders.take(3).map { it.documentId.id })
                    history.next()
                    history.next()
                    history.await { pageIndex == 2 && orders.size == 1 }
                    repository.runEvictionIfDue()
                    history.await { total == 52 && pageIndex == 1 && orders.size == 2 }
                    assertTrue(history.state.value.orders.all { it.createdAt == today })
                    history.setVisible(false)
                    assertTrue(history.state.value.orders.isEmpty())
                    history.setVisible(true)
                    history.await { total == 52 && pageIndex == 1 && orders.size == 2 }
                    history.setLocation("B")
                    history.await { total == 55 && pageIndex == 0 && orders.size == 50 }
                } finally {
                    history.setVisible(false)
                    scope.cancel()
                }
            }
        }
    }

    private suspend fun OrdersHistory.await(predicate: OrdersHistoryState.() -> Boolean) {
        withTimeout(5000) { state.first { it.predicate() } }
    }
}
