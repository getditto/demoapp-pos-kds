package live.ditto.pos.core.data

import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.orders.Order
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

@RunWith(AndroidJUnit4::class)
class OrderStoreRegressionTest {
    @Test
    fun upsertInsertsAndUpdatesTheOrderWithoutDuplicatingIt() = runBlocking {
        TestDitto.withInstance {
            val original = TestDitto.fixture()
            val repository = repository()
            repository.upsert(original)
            assertEquals(original, read(original.documentId))

            val updated = original.addingCartLineItem(original.cart.getValue("line-1").copy(qty = 1), "line-3")
            repository.upsert(updated)
            assertEquals(updated, read(original.documentId))
        }
    }

    @Test
    fun clearPreservesHistoryAndAnotherLocationWithTheSameOrderId() = runBlocking {
        TestDitto.withInstance {
            val original = TestDitto.fixture()
            val other = original.copy(documentId = original.documentId.copy(locationId = "other"))
            insert(original)
            insert(other)

            repository().clearCart(original)

            assertEquals(original.copy(cart = emptyMap()), read(original.documentId))
            assertEquals(other, read(other.documentId))
        }
    }

    @Test
    fun evictionIncludesMidnightAndUnpaidOrdersAndRecordsTheSuccessfulRun() = runBlocking {
        TestDitto.withInstance {
            val midnight = Instant.parse("2026-04-01T00:00:00.000Z")
            val now = Instant.parse("2026-04-01T12:00:00.000Z")
            val fixture = TestDitto.fixture()
            for ((id, date) in listOf(
                "older" to midnight - 1.seconds,
                "midnight" to midnight,
                "after" to midnight + 1.milliseconds
            )) {
                insert(fixture.copy(documentId = DocumentID(id, "42"), payments = emptyMap(), createdAt = date))
            }

            repository(now).runEvictionIfDue()

            val remaining = ditto.store.execute(
                "SELECT * FROM pos_orders WHERE _id.locationId = :locationId",
                mapOf("locationId" to "42")
            ) { it.decode<Order>() }
            assertEquals(listOf("after"), remaining.map { it.documentId.id })
            assertEquals(now.toEpochMilliseconds(), preferences.getLong("v2.lastEvictionAt", 0L))
        }
    }

    @Test
    fun observerAdapterIncludesLocallyPresentDatesAndBindsLocationForInitialAndSubsequentOrders() = runBlocking {
        TestDitto.withInstance {
            val original = TestDitto.fixture()
            insert(original)
            val foreign = original.copy(documentId = original.documentId.copy(locationId = "other"))
            insert(foreign)
            val neighbor = original.copy(documentId = DocumentID("midnight", "42"), createdAt = Instant.parse("2026-04-01T00:00:00.000Z"))
            insert(neighbor)
            insert(original.copy(documentId = DocumentID("older", "42"), createdAt = Instant.parse("2026-03-31T23:59:59.999Z")))
            val repository = repository()
            coroutineScope {
                val observedOrders = Channel<List<Order>>(Channel.UNLIMITED)
                val selected = Channel<Order?>(Channel.UNLIMITED)
                val other = Channel<Order?>(Channel.UNLIMITED)
                val adjacent = Channel<Order?>(Channel.UNLIMITED)
                val collection = launch {
                    repository.observeLocationOrders("42").collect { observedOrders.send(it) }
                }
                val selectedCollection = launch { repository.observeOrder(original.documentId).collect { selected.send(it) } }
                val otherCollection = launch { repository.observeOrder(foreign.documentId).collect { other.send(it) } }
                val adjacentCollection = launch { repository.observeOrder(neighbor.documentId).collect { adjacent.send(it) } }
                try {
                    assertEquals(original, withTimeout(5_000) { selected.receive() })
                    assertEquals(foreign, withTimeout(5_000) { other.receive() })
                    assertEquals(neighbor, withTimeout(5_000) { adjacent.receive() })
                    val initial = withTimeout(5_000) { observedOrders.receive() }
                    assertEquals(setOf(original.documentId.id, "midnight", "older"), initial.map { it.documentId.id }.toSet())
                    assertEquals(setOf("42"), initial.map { it.documentId.locationId }.toSet())
                    val updatedAt = Instant.parse("2026-04-01T13:00:00.123Z")
                    // Simulate a peer update locally, retaining the same live collection.
                    ditto.store.execute(
                        "UPDATE pos_orders SET createdAt = :date WHERE _id.id = :id AND _id.locationId = :locationId",
                        mapOf("date" to updatedAt.toDittoIsoString(), "id" to original.documentId.id, "locationId" to "42")
                    )
                    val updated = withTimeout(5_000) { observedOrders.receive() }
                    assertEquals(original.copy(createdAt = updatedAt), updated.single { it.documentId == original.documentId })
                    assertEquals(original.copy(createdAt = updatedAt), withTimeout(5_000) { selected.receive() })
                    assertEquals(initial.filter { it.documentId != original.documentId }.toSet(), updated.filter { it.documentId != original.documentId }.toSet())
                    val changedForeign = foreign.addingPayment(Payment(PaymentType.DEBIT, foreign.total), "foreign-payment")
                    repository.upsert(changedForeign)
                    val observedForeign = withTimeout(5_000) { other.receive() }
                    assertEquals(changedForeign.payments.keys, observedForeign?.payments?.keys)
                    assertEquals(foreign.documentId, observedForeign?.documentId)
                    assertEquals(original.copy(createdAt = updatedAt), requireNotNull(repository.findOrder(original.documentId)))
                } finally {
                    collection.cancelAndJoin()
                    selectedCollection.cancelAndJoin()
                    otherCollection.cancelAndJoin()
                    adjacentCollection.cancelAndJoin()
                    observedOrders.close()
                    selected.close()
                    other.close()
                    adjacent.close()
                }
            }
        }
    }
}
