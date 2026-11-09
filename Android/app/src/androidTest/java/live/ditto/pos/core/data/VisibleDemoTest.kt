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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.core.presentation.viewmodel.MainViewModel
import live.ditto.pos.kds.KDSViewModel
import live.ditto.pos.kds.KdsUiState
import live.ditto.pos.pos.POSViewModel
import live.ditto.pos.pos.PosUiState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.time.Clock
import kotlin.time.Instant

@RunWith(AndroidJUnit4::class)
class VisibleDemoTest {
    @Test
    fun locationChangePreservesOutgoingOrdersAndStockWhilePOSWasHidden() = runBlocking {
        for (state in listOf("empty", "unpaid", "paid", "canceled")) {
            TestDitto.withInstance {
                settings.setLocationId("A")
                val orders = repository(locationIds = settings.locationIdFlow())
                val catalog = catalog(settings.locationIdFlow())
                catalog.create(SaleItemCreation(SaleItemMetadata(DocumentID("coffee", "A"), "Coffee", "coffee", Price(199)), 2))
                val owner = object : ViewModelStoreOwner {
                    override val viewModelStore = ViewModelStore()
                }
                val provider = ViewModelProvider.create(
                    owner,
                    viewModelFactory { initializer { POSViewModel(settings, orders, catalog, Dispatchers.IO) } }
                )
                val pos = provider[POSViewModel::class]
                val states = Channel<PosUiState>(Channel.UNLIMITED)
                try {
                    coroutineScope {
                        var collection = launch(Dispatchers.Main) { pos.uiState.collect { states.send(it) } }
                        try {
                            val ready = states.await { it.currentOrderId.isNotEmpty() && it.saleItems.size == 1 }
                            assertEquals(ready.currentOrderId.take(8).uppercase(), ready.currentOrderTitle)
                            if (state != "empty") {
                                pos.addItemToCart(ready.saleItems.single())
                                states.await { it.orderItems.size == 1 }
                            }
                            val outgoing = read(DocumentID(ready.currentOrderId, "A"))
                            collection.cancelAndJoin()
                            awaitObserverCount(0)
                            withTimeout(5_000) { while (!pos.uiState.value.isLoading) yield() }
                            assertTrue(pos.uiState.value.orderItems.isEmpty())

                            val retained = outgoing.copy(createdAt = Instant.parse("2026-04-01T12:00:00.000Z"))
                            val changed = when (state) {
                                "paid" -> retained.addingPayment(Payment(PaymentType.CASH, outgoing.total), "other-device")
                                "canceled" -> retained.appendingStatus(OrderStatus.CANCELED, Instant.fromEpochMilliseconds(Clock.System.now().toEpochMilliseconds() + 2_000))
                                else -> retained
                            }
                            ditto.store.execute(
                                "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json)) ON ID CONFLICT DO UPDATE_LOCAL_DIFF",
                                mapOf("json" to changed.dittoJsonString())
                            )
                            val stored = read(outgoing.documentId)
                            assertEquals(state == "paid" || state == "canceled", stored.isPaid)
                            val stockBefore = ditto.store.execute("SELECT * FROM sale_items WHERE _id.locationId = :locationId", mapOf("locationId" to "A")) { it.decode<SaleItem>() }
                            settings.setLocationId("B")
                            collection = launch(Dispatchers.Main) { pos.uiState.collect { states.send(it) } }
                            val destination = states.await { it.currentOrderId.isNotEmpty() && it.currentOrderId != outgoing.documentId.id }
                            assertEquals("B", read(DocumentID(destination.currentOrderId, "B")).documentId.locationId)
                            assertEquals(state, stored, read(outgoing.documentId))
                            val stockAfter = ditto.store.execute("SELECT * FROM sale_items WHERE _id.locationId = :locationId", mapOf("locationId" to "A")) { it.decode<SaleItem>() }
                            assertEquals(state, stockBefore, stockAfter)
                        } finally {
                            collection.cancelAndJoin()
                        }
                    }
                    awaitObserverCount(0)
                } finally {
                    withContext(Dispatchers.Main) { owner.viewModelStore.clear() }
                    states.close()
                }
            }
        }
    }

    @Test
    fun locationReloadHasFreshPendingAndEmptyResultsWithoutChangingConfiguration() = runBlocking {
        TestDitto.withInstance {
            val id = "00001"
            settings.setLocationId(id)
            val groups = Channel<String?>(Channel.UNLIMITED)
            val locations = locations { groups.send(it) }
            assertEquals(id, withTimeout(5_000) { groups.receive() })
            val owner = object : ViewModelStoreOwner {
                override val viewModelStore = ViewModelStore()
            }
            var permissionRefreshes = 0
            val provider = ViewModelProvider.create(
                owner,
                viewModelFactory {
                    initializer {
                        MainViewModel(
                            { permissionRefreshes++ },
                            { error("Presentation must not initialize Ditto") },
                            AppConfigurationStateUseCase(settings),
                            GetCurrentLocationUseCase(locations),
                            { error("Presentation must not request permissions") },
                            locations
                        )
                    }
                }
            )
            val root = provider[MainViewModel::class]
            root.refreshDittoPermissions()
            assertEquals(1, permissionRefreshes)
            assertTrue(root.uiState.value.isLoading)
            val snapshots = Channel<AppState>(Channel.UNLIMITED)
            try {
                assertEquals(AppConfigurationStateUseCase.AppConfigurationState.VALID, withTimeout(5_000) { root.configuration.first { it == AppConfigurationStateUseCase.AppConfigurationState.VALID } })
                coroutineScope {
                    var collection = launch(Dispatchers.Main) { root.uiState.collect { snapshots.send(it) } }
                    try {
                        snapshots.await { !it.isLoading && it.locations.isEmpty() }
                        DemoSeeder(ditto).seedLocations()
                        snapshots.await { it.locations.size == 7 && it.currentLocationName == "Ham's Burgers" }
                        collection.cancelAndJoin()
                        awaitObserverCount(0)
                        withTimeout(5_000) { while (!root.uiState.value.isLoading) yield() }
                        assertTrue(root.uiState.value.locations.isEmpty())
                        assertEquals("", root.uiState.value.currentLocationName)
                        assertEquals(AppConfigurationStateUseCase.AppConfigurationState.VALID, root.configuration.value)
                        while (snapshots.tryReceive().isSuccess) { }

                        ditto.store.execute("UPDATE locations SET name = :name WHERE _id = :id", mapOf("name" to "Renamed location", "id" to id))
                        collection = launch(Dispatchers.Main) { root.uiState.collect { snapshots.send(it) } }
                        val fresh = snapshots.await { !it.isLoading && it.currentLocationName == "Renamed location" }
                        assertEquals("Renamed location", fresh.locations.single { it.id == id }.name)
                        assertEquals(id, settings.locationId())
                        assertEquals(AppConfigurationStateUseCase.AppConfigurationState.VALID, root.configuration.value)
                        assertTrue(groups.tryReceive().isFailure)
                        collection.cancelAndJoin()
                        awaitObserverCount(0)
                        withTimeout(5_000) { while (!root.uiState.value.isLoading) yield() }
                        while (snapshots.tryReceive().isSuccess) { }

                        ditto.store.execute("DELETE FROM locations")
                        collection = launch(Dispatchers.Main) { root.uiState.collect { snapshots.send(it) } }
                        snapshots.await { !it.isLoading && it.locations.isEmpty() && it.currentLocationName.isEmpty() }
                        assertEquals(id, settings.locationId())
                        assertEquals(AppConfigurationStateUseCase.AppConfigurationState.VALID, root.configuration.value)
                    } finally {
                        collection.cancelAndJoin()
                    }
                }
            } finally {
                withContext(Dispatchers.Main) { owner.viewModelStore.clear() }
                snapshots.close()
                groups.close()
            }
        }
    }

    @Test
    fun storedCartSurvivesRelaunchAndMidnightTabReentryUntilEviction() = runBlocking {
        TestDitto.withInstance {
            settings.setLocationId("A")
            var now = Instant.parse("2026-04-01T09:00:00.000Z")
            preferences.edit().putLong("v2.lastEvictionAt", Instant.parse("2026-03-31T12:00:00.000Z").toEpochMilliseconds()).commit()
            val orders = repository(locationIds = settings.locationIdFlow(), clock = { now })
            val catalog = catalog(settings.locationIdFlow())
            val stored = Order.new("A", createdAt = Instant.parse("2026-03-31T18:00:00.000Z"))
                .addingCartLineItem(TestDitto.fixture().cart.values.first(), lineItemId = "retained-line")
            insert(stored)
            settings.setCurrentOrderId(stored.documentId.id)
            orders.runEvictionIfDue()
            assertEquals(stored, read(stored.documentId))
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
                    var collection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                    try {
                        val initial = posStates.await { it.currentOrderId.isNotEmpty() && it.saleItems.size == 1 }
                        assertEquals(stored.documentId.id, initial.currentOrderId)
                        pos.addItemToCart(initial.saleItems.single())
                        posStates.await { it.orderItems.size == 2 }
                    } finally {
                        collection.cancelAndJoin()
                    }
                    awaitObserverCount(0)
                    now = Instant.parse("2026-04-02T09:00:00.000Z")
                    var tickets = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                    try {
                        val ready = kitchenStates.await { it.tickets.size == 1 }
                        assertEquals(stored.documentId.id, ready.tickets.single().orderId)
                        assertEquals(1, ready.tickets.single().items["Coffee"])
                    } finally {
                        tickets.cancelAndJoin()
                    }
                    collection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                    try {
                        posStates.await { it.currentOrderId == stored.documentId.id && it.orderItems.size == 2 }
                    } finally {
                        collection.cancelAndJoin()
                    }
                    awaitObserverCount(0)
                    val subscription = ditto.sync.subscriptions.single { it.queryString.contains("pos_orders") }
                    val args = dittoJson.parseToJsonElement(requireNotNull(subscription.queryArgumentsJsonString)).jsonObject
                    assertEquals("2026-03-31T00:00:00.000Z", args.getValue("TTL").jsonPrimitive.content)
                    tickets = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                    try {
                        kitchenStates.await { it.tickets.size == 1 }
                        orders.runEvictionIfDue()
                        kitchenStates.await { it.tickets.isEmpty() }
                        assertTrue(subscription.isClosed)
                    } finally {
                        tickets.cancelAndJoin()
                    }
                    collection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                    try {
                        val fresh = posStates.await { it.currentOrderId.isNotEmpty() && it.currentOrderId != stored.documentId.id }
                        assertTrue(fresh.orderItems.isEmpty())
                        assertEquals(now.toEpochMilliseconds(), preferences.getLong("v2.lastEvictionAt", 0L))
                    } finally {
                        collection.cancelAndJoin()
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
                        assertFalse(initial.isLoading)
                        val firstID = initial.currentOrderId
                        awaitObserverCount(baseline + 2)
                        // Adding quantity metadata must preserve existing checkout behavior.
                        pos.addItemToCart(initial.saleItems.single())
                        val cart = posStates.await { it.orderItems.isNotEmpty() }
                        assertEquals(firstID, cart.currentOrderId)
                        val originalCart = read(DocumentID(firstID, "A"))
                        catalog.updateMetadata(metadata.copy(name = "Live update", imageName = "milk", price = Price(250)))
                        val live = posStates.await { it.saleItems.singleOrNull()?.label == "Live update" && it.saleItems.single().price == 2.5 }
                        assertEquals(ImageNameMapping.resourceFor("milk"), live.saleItems.single().imageResource)
                        assertEquals(cart.orderItems, live.orderItems)
                        assertEquals(originalCart, read(DocumentID(firstID, "A")))
                        posCollection.cancelAndJoin()
                        awaitObserverCount(baseline)
                        withTimeout(5_000) { while (!pos.uiState.value.isLoading) yield() }
                        assertTrue(pos.uiState.value.orderItems.isEmpty())
                        assertTrue(pos.uiState.value.saleItems.isEmpty())

                        catalog.updateMetadata(metadata.copy(name = "Renamed", imageName = "milk", price = Price(0)))
                        kitchenCollection = launch(Dispatchers.Main) { kitchen.uiState.collect { kitchenStates.send(it) } }
                        val preparing = kitchenStates.await { it.tickets.size == 1 }
                        assertFalse(preparing.isLoading)
                        awaitObserverCount(baseline + 1)
                        assertFalse(ditto.store.observers.any { it.queryString.contains("sale_items") })
                        kitchen.updateTicketStatus(preparing.tickets.single().orderId)
                        kitchenStates.await { it.tickets.singleOrNull()?.orderStatus == OrderStatus.PROCESSED }
                        kitchenCollection.cancelAndJoin()
                        awaitObserverCount(baseline)
                        withTimeout(5_000) { while (!kitchen.uiState.value.isLoading) yield() }
                        assertTrue(kitchen.uiState.value.tickets.isEmpty())

                        posCollection = launch(Dispatchers.Main) { pos.uiState.collect { posStates.send(it) } }
                        val returned = posStates.await { it.saleItems.map { item -> item.label } == listOf("Renamed") && it.orderItems.isNotEmpty() }
                        assertFalse(returned.isLoading)
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
                        kitchenStates.await { !it.isLoading && it.tickets.isEmpty() }
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
