package live.ditto.pos.inventory

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.SaleItem

data class QuantityEdit(val id: DocumentID, val text: String) {
    val value: Long? get() = if (error == null) text.toLongOrNull() else null
    val error: String? get() = when {
        text.isEmpty() -> "Enter a quantity."
        text.any { it !in '0'..'9' } -> "Use a whole number of 0 or more."
        text.toLongOrNull() == null -> "Quantity is too large."
        else -> null
    }
}

data class InventoryState(val items: List<SaleItem> = emptyList(), val isLoading: Boolean = true, val edit: QuantityEdit? = null)

class InventoryModel(
    private val scope: CoroutineScope,
    private val observe: (String) -> Flow<List<SaleItem>>,
    private val increment: suspend (Long, DocumentID) -> Unit,
    private val restart: suspend (Long, DocumentID) -> Unit
) {
    private val mutableState = MutableStateFlow(InventoryState())
    val state = mutableState.asStateFlow()
    private var location: String? = null
    private var visible = false
    private var observation: Job? = null
    private var generation = 0

    fun setLocation(location: String?) {
        if (this.location == location) return
        this.location = location
        updateObservation()
    }

    fun setVisible(visible: Boolean) {
        if (this.visible == visible) return
        this.visible = visible
        updateObservation()
    }

    fun beginEditing(id: DocumentID) {
        val item = item(id) ?: return
        mutableState.value = state.value.copy(edit = QuantityEdit(id, item.quantity.toString()))
    }
    fun updateText(text: String) {
        mutableState.value = state.value.copy(edit = state.value.edit?.copy(text = text))
    }
    fun cancelEditing() {
        mutableState.value = state.value.copy(edit = null)
    }

    suspend fun step(delta: Long, id: DocumentID) {
        if (delta != 1L && delta != -1L || state.value.edit?.id == id) return
        val item = item(id) ?: return
        if (delta < 0 && item.quantity <= 0) return
        increment(delta, id)
    }

    suspend fun submit() {
        val edit = state.value.edit ?: return
        val value = edit.value ?: return
        if (item(edit.id) == null) return
        // Consume before suspension: IME and toolbar Done share this handler.
        cancelEditing()
        restart(value, edit.id)
    }

    private fun item(id: DocumentID): SaleItem? =
        if (visible && id.locationId == location) state.value.items.firstOrNull { it.documentId == id } else null

    private fun updateObservation() {
        generation++
        observation?.cancel()
        observation = null
        mutableState.value = InventoryState()
        val currentLocation = location?.takeIf { visible } ?: return
        val current = generation
        observation = scope.launch {
            observe(currentLocation).collect { items ->
                if (generation != current) return@collect
                val edit = state.value.edit?.takeIf { draft -> items.any { it.documentId == draft.id } }
                mutableState.value = InventoryState(items, isLoading = false, edit = edit)
            }
        }
    }
}
