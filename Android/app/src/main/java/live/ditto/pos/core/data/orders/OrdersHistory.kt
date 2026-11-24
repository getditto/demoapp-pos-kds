package live.ditto.pos.core.data.orders

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable

object OrdersHistoryQuery {
    const val PAGE_SIZE = 50
    private const val PREDICATE = "_id.locationId = :locationId AND object_length(cart) > 0"
    const val PAGE = "SELECT * FROM ${Order.COLLECTION_NAME} WHERE $PREDICATE ORDER BY createdAt DESC LIMIT 50 OFFSET :offset"
    const val COUNT = "SELECT COUNT(*) AS total FROM ${Order.COLLECTION_NAME} WHERE $PREDICATE"

    @Serializable data class Count(val total: Int)
}

data class OrdersHistoryState(val orders: List<Order> = emptyList(), val pageIndex: Int = 0, val total: Int? = null, val isPageLoading: Boolean = true) {
    val isLoading: Boolean get() = total == null || isPageLoading
    val totalPages: Int get() = maxOf(1, ((total ?: 0) + OrdersHistoryQuery.PAGE_SIZE - 1) / OrdersHistoryQuery.PAGE_SIZE)
    val canPrevious: Boolean get() = total != null && pageIndex > 0
    val canNext: Boolean get() = total != null && pageIndex + 1 < totalPages
}

class OrdersHistory(
    private val scope: CoroutineScope,
    private val observePage: (String, Int) -> Flow<List<Order>>,
    private val observeCount: (String) -> Flow<Int>
) {
    private val mutableState = MutableStateFlow(OrdersHistoryState())
    val state = mutableState.asStateFlow()
    private var location: String? = null
    private var visible = false
    private var generation = 0
    private var pageGeneration = 0
    private var pageJob: Job? = null
    private var countJob: Job? = null
    private var receivedOrders = emptyList<Order>()

    fun setLocation(location: String?) {
        if (this.location == location) return
        stop()
        this.location = location
        mutableState.value = OrdersHistoryState()
        start()
    }

    fun setVisible(visible: Boolean) {
        if (this.visible == visible) return
        this.visible = visible
        stop()
        mutableState.value = state.value.copy(orders = emptyList(), total = null, isPageLoading = true)
        start()
    }

    fun previous() {
        if (state.value.canPrevious) select(state.value.pageIndex - 1)
    }
    fun next() {
        if (state.value.canNext) select(state.value.pageIndex + 1)
    }

    private fun select(index: Int) {
        receivedOrders = emptyList()
        mutableState.value = state.value.copy(pageIndex = index, orders = emptyList(), isPageLoading = true)
        updatePage()
    }

    private fun start() {
        val location = location?.takeIf { visible } ?: return
        val current = generation
        // COUNT stays attached during pagination; neither observer changes document sync.
        // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
        countJob = scope.launch {
            observeCount(location).collect { total ->
                if (generation != current) return@collect
                mutableState.value = state.value.copy(total = total)
                val lastIndex = state.value.totalPages - 1
                if (state.value.pageIndex > lastIndex) select(lastIndex)
                mutableState.value = state.value.copy(orders = if (total == 0) emptyList() else receivedOrders)
            }
        }
        updatePage()
    }

    private fun updatePage() {
        pageGeneration++
        pageJob?.cancel()
        val location = location?.takeIf { visible } ?: return
        val current = generation
        val pageCurrent = pageGeneration
        val index = state.value.pageIndex
        pageJob = scope.launch {
            observePage(location, index).collect { orders ->
                if (generation != current || pageGeneration != pageCurrent) return@collect
                receivedOrders = orders
                mutableState.value = state.value.copy(orders = if (state.value.total == 0) emptyList() else orders, isPageLoading = false)
            }
        }
    }

    private fun stop() {
        generation++
        pageGeneration++
        pageJob?.cancel()
        countJob?.cancel()
        pageJob = null
        countJob = null
        receivedOrders = emptyList()
    }
}
