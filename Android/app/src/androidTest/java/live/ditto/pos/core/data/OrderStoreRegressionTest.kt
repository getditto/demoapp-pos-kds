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
    fun resetClearsNonemptyAndEmptyCartsAndChangesOnlyTheirCreationDate() = runBlocking {
        for (empty in listOf(false, true)) {
            TestDitto.withInstance {
                val fixture = TestDitto.fixture()
                val original = if (empty) fixture.copy(cart = emptyMap()) else fixture
                val other = original.copy(documentId = original.documentId.copy(locationId = "other"))
                val resetAt = Instant.parse("2026-05-01T10:20:30.123Z")
                insert(original)
                insert(other)

                repository(resetAt).reset(original)

                assertEquals(original.copy(cart = emptyMap(), createdAt = resetAt), read(original.documentId))
                assertEquals(other, read(other.documentId))
            }
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
    fun observerAdapterBindsLocationAndCutoffAndDecodesInitialAndSubsequentOrders() = runBlocking {
        TestDitto.withInstance {
            val original = TestDitto.fixture()
            insert(original)
            insert(original.copy(documentId = original.documentId.copy(locationId = "other")))
            insert(original.copy(documentId = DocumentID("midnight", "42"), createdAt = Instant.parse("2026-04-01T00:00:00.000Z")))
            insert(original.copy(documentId = DocumentID("older", "42"), createdAt = Instant.parse("2026-03-31T23:59:59.999Z")))
            val repository = repository()
            coroutineScope {
                val snapshots = Channel<List<Order>>(Channel.UNLIMITED)
                val collection = launch {
                    repository.observeLocationOrders("42").collect { snapshots.send(it) }
                }
                try {
                    assertEquals(listOf(original), withTimeout(5_000) { snapshots.receive() })
                    val updatedAt = Instant.parse("2026-04-01T13:00:00.123Z")
                    // Simulate a peer update locally, retaining the same live collection.
                    ditto.store.execute(
                        "UPDATE pos_orders SET createdAt = :date WHERE _id.id = :id AND _id.locationId = :locationId",
                        mapOf("date" to updatedAt.toDittoIsoString(), "id" to original.documentId.id, "locationId" to "42")
                    )
                    assertEquals(listOf(original.copy(createdAt = updatedAt)), withTimeout(5_000) { snapshots.receive() })
                } finally {
                    collection.cancelAndJoin()
                    snapshots.close()
                }
            }
        }
    }
}
