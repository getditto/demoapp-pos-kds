package live.ditto.pos.inventory

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class InventoryModelTest {
    private val id = DocumentID("coffee", "A")
    private val item = SaleItem(id, "Coffee", Price(195), 2)
    private data class Command(val operation: String, val value: Long, val id: DocumentID)

    @Test
    fun invalidAndCanceledDraftsNeverWriteAndDuplicateDoneRestartsOnlyOnce() = runBlocking {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val commands = mutableListOf<Command>()
        val started = CompletableDeferred<Unit>()
        val completion = CompletableDeferred<Unit>()
        val model = InventoryModel(scope, { MutableStateFlow(listOf(item)) }, { value, id ->
            commands += Command("increment", value, id)
            started.complete(Unit)
        }, { value, id ->
            commands += Command("restart", value, id)
            started.complete(Unit)
            completion.await()
        })
        try {
            model.setLocation("A")
            model.setVisible(true)
            for (text in listOf("", "-1", "1.5", " 2", "+2", "1e3", "9223372036854775808")) {
                model.beginEditing(id)
                model.updateText(text)
                assertNotNull(text, model.state.value.edit?.error)
                model.submit()
                assertEquals(text, model.state.value.edit?.text)
            }
            assertTrue(commands.isEmpty())
            model.updateText("12")
            model.cancelEditing()
            model.submit()
            assertTrue(commands.isEmpty())
            model.beginEditing(id)
            model.updateText("0")
            val firstDone = scope.launch { model.submit() }
            withTimeout(2000) { started.await() }
            assertNull(model.state.value.edit)
            if (model.state.value.edit == null) model.submit()
            assertEquals(listOf(Command("restart", 0, id)), commands)
            assertNull(model.state.value.edit)
            completion.complete(Unit)
            firstDone.join()
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun signedStepsRespectEditingAndLatestObservedStockWithoutReplacingTheDraft() = runBlocking {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        val observed = MutableStateFlow(listOf(item))
        val commands = mutableListOf<Command>()
        val model = InventoryModel(scope, { observed }, { value, id -> commands += Command("increment", value, id) }, { value, id -> commands += Command("restart", value, id) })
        try {
            model.setLocation("A")
            model.setVisible(true)
            model.step(-1, id)
            model.step(1, id)
            model.beginEditing(id)
            model.updateText("6")
            model.step(1, id)
            observed.value = listOf(item.copy(quantity = -2))
            assertEquals(-2L, model.state.value.items.first().quantity)
            assertEquals("6", model.state.value.edit?.text)
            val drafting = InventoryRowViewModel(model.state.value.items.first(), model.state.value.edit)
            assertEquals("6", drafting.text)
            assertFalse(drafting.invalid)
            assertFalse(drafting.canDecrement)
            assertFalse(drafting.canIncrement)
            model.cancelEditing()
            val observedRow = InventoryRowViewModel(model.state.value.items.first(), model.state.value.edit)
            assertEquals("-2", observedRow.text)
            assertTrue(observedRow.invalid)
            assertFalse(observedRow.canDecrement)
            assertTrue(observedRow.canIncrement)
            model.step(-1, id)
            model.step(1, id)
            model.step(1, id.copy(locationId = "B"))
            model.setVisible(false)
            model.step(1, id)
            assertEquals(listOf(Command("increment", -1, id), Command("increment", 1, id), Command("increment", 1, id)), commands)
        } finally {
            scope.cancel()
        }
    }
}
