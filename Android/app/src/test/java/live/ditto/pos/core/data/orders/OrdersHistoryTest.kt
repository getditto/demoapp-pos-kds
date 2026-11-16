package live.ditto.pos.core.data.orders

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.runBlocking
import live.ditto.pos.core.data.dittoJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OrdersHistoryTest {
    @Test
    fun independentDeliveriesRetainCountClampAndRejectObsoletePageAndLocation() = runBlocking {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val pages = mutableListOf<LateFlow<List<Order>>>()
        val counts = mutableListOf<LateFlow<Int>>()
        val order = javaClass.classLoader!!.getResourceAsStream("order.json")!!.bufferedReader().use { dittoJson.decodeFromString<Order>(it.readText()) }
        val history = OrdersHistory(scope, { _, _ -> LateFlow<List<Order>>().also(pages::add) }, { LateFlow<Int>().also(counts::add) })
        try {
            history.setLocation("A")
            history.setVisible(true)
            assertTrue(history.state.value.isLoading)
            pages[0].deliver(listOf(order))
            assertTrue(history.state.value.isLoading)
            counts[0].deliver(0)
            assertFalse(history.state.value.isLoading)
            assertTrue(history.state.value.orders.isEmpty())
            counts[0].deliver(101)
            assertEquals(listOf(order), history.state.value.orders)
            history.next()
            history.next()
            assertTrue(history.state.value.isLoading)
            assertEquals(1, counts.size)
            assertEquals(1, pages[0].stops)
            pages[0].deliver(listOf(order))
            assertTrue(history.state.value.orders.isEmpty())
            history.setVisible(false)
            assertEquals(1, counts[0].stops)
            counts[0].deliver(500)
            pages[2].deliver(listOf(order))
            assertNull(history.state.value.total)
            assertTrue(history.state.value.orders.isEmpty())
            history.setVisible(true)
            counts[1].deliver(49)
            assertEquals(0, history.state.value.pageIndex)
            pages[3].deliver(listOf(order))
            assertTrue(history.state.value.isLoading)
            assertTrue(history.state.value.orders.isEmpty())
            pages[4].deliver(listOf(order))
            assertFalse(history.state.value.isLoading)
            assertEquals(listOf(order), history.state.value.orders)
            history.setLocation("B")
            counts[1].deliver(500)
            pages[4].deliver(listOf(order))
            assertNull(history.state.value.total)
            assertTrue(history.state.value.orders.isEmpty())
            assertEquals(0, history.state.value.pageIndex)
        } finally {
            scope.cancel()
        }
    }

    // Native callbacks may already be queued when cancellation replaces an observer.
    private class LateFlow<T> : Flow<T> {
        private lateinit var collector: FlowCollector<T>
        var stops = 0
        override suspend fun collect(collector: FlowCollector<T>): Nothing {
            this.collector = collector
            try {
                awaitCancellation()
            } finally {
                stops++
            }
        }
        suspend fun deliver(value: T) {
            collector.emit(value)
        }
    }
}
