package live.ditto.pos.core.data

import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.kds.KDSViewModel
import live.ditto.pos.kds.KdsUiState
import live.ditto.pos.pos.POSViewModel
import live.ditto.pos.pos.PosUiState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.time.Instant

@RunWith(AndroidJUnit4::class)
class VisibleDemoTest {
    @Test
    fun savedPriorDayCartDoesNotHideNewSalesFromKitchenWhenEvictionIsNotDue() = runBlocking {
        TestDitto.withInstance {
            settings.setLocationId("A")
            val now = Instant.parse("2026-04-01T09:00:00.000Z")
            val orders = repository(now, settings.locationIdFlow())
            val catalog = catalog(settings.locationIdFlow())
            val old = Order.new("A", createdAt = Instant.parse("2026-03-31T18:00:00.000Z"))
                .addingCartLineItem(TestDitto.fixture().cart.values.first(), lineItemId = "retained-line")
            insert(old)
            settings.setCurrentOrderId(old.documentId.id)
            preferences.edit().putLong("v2.lastEvictionAt", Instant.parse("2026-03-31T12:00:00.000Z").toEpochMilliseconds()).commit()
            orders.runEvictionIfDue()
            assertEquals(old, read(old.documentId))
            catalog.create(SaleItemCreation(SaleItemMetadata(DocumentID("coffee", "A"), "Coffee", "coffee", Price(199)), 2))
            val owner = object : ViewModelStoreOwner {
                override val viewModelStore = ViewModelStore()
            }
            val provider = ViewModelProvider.create(
                owner,
                viewModelFactory {
                    initializer { POSViewModel(settings, orders, catalog, Dispatchers.IO) }
                    initializer { KDSViewModel(settings, orders, Dispatchers.IO) }
                }
            )
            val pos = provider[POSViewModel::class]
            val kitchen = provider[KDSViewModel::class]
            val posStates = Channel<PosUiState>(Channel.UNLIMITED)
            val kitchenStates = Channel<KdsUiState>(Channel.UNLIMITED)
            try {
                coroutineScope {
                    val collection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                    val freshID = try {
                        val initial = posStates.await { it.currentOrderId.isNotEmpty() && it.saleItems.size == 1 }
                        assertNotEquals(old.documentId.id, initial.currentOrderId)
                        pos.addItemToCart(initial.saleItems.single())
                        posStates.await { it.orderItems.isNotEmpty() }.currentOrderId
                    } finally {
                        collection.cancelAndJoin()
                    }
                    awaitObserverCount(0)
                    val tickets = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                    try {
                        val ready = kitchenStates.await { it.tickets.size == 1 }
                        assertEquals(freshID, ready.tickets.single().orderId)
                        assertEquals(mapOf("Coffee" to 1), ready.tickets.single().items)
                        assertEquals(old, read(old.documentId))
                    } finally {
                        tickets.cancelAndJoin()
                    }
                }
            } finally {
                withContext(Dispatchers.Main) { owner.viewModelStore.clear() }
                posStates.close()
                kitchenStates.close()
            }
        }
    }

    @Test
    fun tabsOwnOnlyTheirQueriesAndReturnToTheSameCartWithFreshCatalogAndOrderData() = runBlocking {
        TestDitto.withInstance {
            settings.setLocationId("A")
            val orders = repository(Instant.fromEpochMilliseconds(0), settings.locationIdFlow())
            val catalog = catalog(settings.locationIdFlow())
            val metadata = SaleItemMetadata(DocumentID("coffee", "A"), "Original", "coffee", Price(199))
            catalog.create(SaleItemCreation(metadata, 0))
            catalog.create(SaleItemCreation(metadata.copy(documentId = metadata.documentId.copy(locationId = "B"), name = "Other location", price = Price(250)), 7))
            val owner = object : ViewModelStoreOwner {
                override val viewModelStore = ViewModelStore()
            }
            val provider = ViewModelProvider.create(
                owner,
                viewModelFactory {
                    initializer { POSViewModel(settings, orders, catalog, Dispatchers.IO) }
                    initializer { KDSViewModel(settings, orders, Dispatchers.IO) }
                }
            )
            val pos = provider[POSViewModel::class]
            val kitchen = provider[KDSViewModel::class]
            val baseline = ditto.store.observers.size
            val posStates = Channel<PosUiState>(Channel.UNLIMITED)
            val kitchenStates = Channel<KdsUiState>(Channel.UNLIMITED)
            try {
                coroutineScope {
                    var posCollection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                    var kitchenCollection: kotlinx.coroutines.Job? = null
                    try {
                        val initial = posStates.await { it.saleItems.map { item -> item.label } == listOf("Original") }
                        val firstID = initial.currentOrderId
                        awaitObserverCount(baseline + 2)
                        val orderQuery = ditto.store.observers.single { it.queryString.contains("pos_orders") }
                        assertTrue(orderQuery.queryString.contains("_id.id = :id"))
                        assertTrue(orderQuery.queryString.contains("_id.locationId = :locationId"))
                        // Until137, stock zero must not disable the existing POS.
                        pos.addItemToCart(initial.saleItems.single())
                        val cart = posStates.await { it.orderItems.isNotEmpty() }
                        assertEquals(firstID, cart.currentOrderId)
                        posCollection.cancelAndJoin()
                        awaitObserverCount(baseline)

                        catalog.updateMetadata(metadata.copy(name = "Renamed", imageName = "milk", price = Price(0)))
                        kitchenCollection = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                        val preparing = kitchenStates.await { it.tickets.size == 1 }
                        awaitObserverCount(baseline + 1)
                        assertFalse(ditto.store.observers.any { it.queryString.contains("sale_items") })
                        kitchen.updateTicketStatus(preparing.tickets.single().orderId)
                        kitchenStates.await { it.tickets.singleOrNull()?.orderStatus == OrderStatus.PROCESSED }
                        kitchenCollection.cancelAndJoin()
                        awaitObserverCount(baseline)

                        posCollection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                        val returned = posStates.await { it.saleItems.map { item -> item.label } == listOf("Renamed") && it.orderItems.isNotEmpty() }
                        assertEquals(firstID, returned.currentOrderId)
                        val saved = read(DocumentID(firstID, "A"))
                        assertEquals("Original", saved.cart.values.single().name)
                        assertEquals(199, saved.cart.values.single().price.amount)
                        awaitObserverCount(baseline + 2)

                        pos.clearItems()
                        posStates.await { it.currentOrderId == firstID && it.orderItems.isEmpty() }
                        pos.addItemToCart(returned.saleItems.single())
                        posStates.await { it.currentOrderId == firstID && it.orderItems.isNotEmpty() }
                        pos.payForOrder()
                        posStates.await { it.currentOrderId != firstID && it.currentOrderId.isNotEmpty() && it.orderItems.isEmpty() }
                        assertTrue(read(DocumentID(firstID, "A")).isPaid)
                        assertEquals(0, read(DocumentID(firstID, "A")).total.amount)
                        awaitObserverCount(baseline + 2)

                        settings.setLocationId("B")
                        val other = posStates.await { it.saleItems.map { item -> item.label } == listOf("Other location") }
                        assertTrue(other.saleItems.all { it.locationId == "B" })
                        assertEquals("B", read(DocumentID(other.currentOrderId, "B")).documentId.locationId)
                        settings.setLocationId("")
                        posStates.await { it.currentOrderId.isEmpty() && it.saleItems.isEmpty() }
                        awaitObserverCount(baseline)
                        settings.setLocationId("B")
                        posStates.await { it.saleItems.map { item -> item.label } == listOf("Other location") }
                        awaitObserverCount(baseline + 2)
                    } finally {
                        posCollection.cancelAndJoin()
                        kitchenCollection?.cancelAndJoin()
                    }
                }
                awaitObserverCount(baseline)
                assertEquals(2, ditto.sync.subscriptions.size)
                coroutineScope {
                    val collection = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                    try {
                        awaitObserverCount(baseline + 1)
                        settings.setLocationId("")
                        awaitObserverCount(baseline)
                        kitchenStates.await { it.tickets.isEmpty() }
                    } finally {
                        collection.cancelAndJoin()
                    }
                }
                withTimeout(5_000) { while (ditto.sync.subscriptions.isNotEmpty()) yield() }
            } finally {
                withContext(Dispatchers.Main) { owner.viewModelStore.clear() }
                posStates.close()
                kitchenStates.close()
            }
        }
    }

    private suspend fun <T> Channel<T>.await(predicate: (T) -> Boolean): T = withTimeout(5_000) {
        var value = receive()
        while (!predicate(value)) value = receive()
        value
    }

    private suspend fun TestDitto.awaitObserverCount(count: Int) = withTimeout(5_000) {
        while (ditto.store.observers.size != count) yield()
    }
}
