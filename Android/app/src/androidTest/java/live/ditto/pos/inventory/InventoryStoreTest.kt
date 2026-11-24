package live.ditto.pos.inventory

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.SaleItemCreation
import live.ditto.pos.core.data.SaleItemMetadata
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.data.decode
import live.ditto.pos.core.data.orders.Order
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class InventoryStoreTest {
    @Test
    fun manualInventoryObservesScopedStockAndCancelsDraftsAcrossVisibilityAndLocation() = runBlocking {
        TestDitto.withInstance {
            val locations = MutableStateFlow("A")
            val repository = catalog(locations)
            val local = DocumentID("coffee", "A")
            val foreign = local.copy(locationId = "B")
            for ((id, quantity) in listOf(local to 2L, foreign to 7L)) {
                repository.create(SaleItemCreation(SaleItemMetadata(id, "Coffee", Price(195)), quantity))
            }
            suspend fun quantity(id: DocumentID) = ditto.store.execute(
                "SELECT * FROM ${SaleItem.COLLECTION_NAME} WHERE _id.id = :id AND _id.locationId = :locationId",
                mapOf("id" to id.id, "locationId" to id.locationId)
            ) { it.decode<SaleItem>().single().quantity }
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
            val model = InventoryModel(scope, repository::observeLocationSaleItems, repository::increment, repository::restart)
            suspend fun expected(quantity: Long) = withTimeout(5000) { model.state.first { !it.isLoading && it.items.firstOrNull()?.quantity == quantity } }
            try {
                assertTrue(ditto.store.observers.isEmpty())
                withContext(Dispatchers.Main) {
                    model.setLocation("A")
                    model.setVisible(true)
                }
                expected(2)
                assertEquals(listOf(local), model.state.value.items.map { it.documentId })
                withContext(Dispatchers.Main) { model.step(-1, local) }
                expected(1)
                withContext(Dispatchers.Main) { model.step(1, local) }
                expected(2)
                repository.increment(-5, local)
                expected(-3)
                withContext(Dispatchers.Main) { model.step(-1, local) }
                assertEquals(-3L, quantity(local))
                withContext(Dispatchers.Main) { model.step(1, local) }
                expected(-2)
                withContext(Dispatchers.Main) {
                    model.beginEditing(local)
                    model.updateText("6")
                }
                assertEquals(-2L, quantity(local))
                withContext(Dispatchers.Main) {
                    model.cancelEditing()
                    model.submit()
                }
                assertEquals(-2L, quantity(local))
                withContext(Dispatchers.Main) {
                    model.beginEditing(local)
                    model.updateText("6")
                    model.submit()
                }
                expected(6)
                withContext(Dispatchers.Main) {
                    model.beginEditing(local)
                    model.updateText("99")
                    model.setVisible(false)
                }
                assertNull(model.state.value.edit)
                assertTrue(model.state.value.items.isEmpty())
                assertTrue(ditto.store.observers.isEmpty())
                assertTrue(ditto.sync.subscriptions.isNotEmpty())
                repository.restart(9, local)
                withContext(Dispatchers.Main) {
                    model.setVisible(true)
                    assertTrue(model.state.value.isLoading)
                }
                expected(9)
                withContext(Dispatchers.Main) {
                    model.beginEditing(local)
                    model.updateText("88")
                    locations.value = "B"
                    model.setLocation("B")
                    assertTrue(model.state.value.isLoading)
                    assertNull(model.state.value.edit)
                    model.submit()
                }
                expected(7)
                assertEquals(listOf(foreign), model.state.value.items.map { it.documentId })
                assertEquals(9L, quantity(local))
                withContext(Dispatchers.Main) { model.beginEditing(foreign) }
                ditto.store.execute("DELETE FROM ${SaleItem.COLLECTION_NAME} WHERE _id.id = :id AND _id.locationId = :locationId", mapOf("id" to foreign.id, "locationId" to "B"))
                withTimeout(5000) { model.state.first { !it.isLoading && it.items.isEmpty() && it.edit == null } }
                ditto.store.execute("SELECT * FROM ${Order.COLLECTION_NAME}") { assertTrue(it.items.isEmpty()) }
            } finally {
                withContext(Dispatchers.Main) { model.setVisible(false) }
                scope.cancel()
            }
        }
    }
}
