package live.ditto.pos.orders

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrdersHistoryState
import live.ditto.ui.AppEmptyState
import live.ditto.ui.AppEmptyStateStyle
import live.ditto.ui.AppLayout
import live.ditto.ui.AppOrderSummary
import live.ditto.ui.AppPagination
import live.ditto.ui.AppStatusTone
import live.ditto.ui.R
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun OrdersScreen(viewModel: OrdersViewModel = hiltViewModel()) {
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(viewModel, lifecycle) {
        val observer = LifecycleEventObserver { _, _ -> viewModel.history.setVisible(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) }
        lifecycle.addObserver(observer)
        viewModel.history.setVisible(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED))
        onDispose {
            lifecycle.removeObserver(observer)
            viewModel.history.setVisible(false)
        }
    }
    val state by viewModel.history.state.collectAsStateWithLifecycle()
    OrdersContent(state, viewModel.history::previous, viewModel.history::next)
}

@Composable
fun OrdersContent(state: OrdersHistoryState, previous: () -> Unit, next: () -> Unit, modifier: Modifier = Modifier) {
    val listState = rememberLazyListState()
    LaunchedEffect(state.pageIndex) { listState.scrollToItem(0) }
    BoxWithConstraints(modifier.fillMaxSize().padding(horizontal = AppLayout.padding, vertical = AppLayout.padding)) {
        val expanded = maxWidth >= 760.dp
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (state.isLoading) {
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
            } else if (state.orders.isEmpty()) {
                BoxWithConstraints(Modifier.weight(1f).fillMaxWidth()) {
                    val viewportHeight = maxHeight
                    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).heightIn(min = viewportHeight), verticalArrangement = Arrangement.Center) {
                        AppEmptyState("No orders yet", "Orders for this location will appear here.", R.drawable.phosphor_receipt, style = AppEmptyStateStyle.LARGE)
                    }
                }
            } else {
                LazyColumn(Modifier.weight(1f), state = listState, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.orders, key = { it.documentId.id }) { order ->
                        val (status, tone) = order.historyStatus()
                        AppOrderSummary("Order #${order.title}", order.summary.toSortedMap().entries.joinToString(" · ") { "${it.value} × ${it.key}" }, status, tone, order.historyDate(), order.total.formatted(), expanded)
                    }
                }
            }
            if (state.total != null) {
                AppPagination("Page ${state.pageIndex + 1} of ${state.totalPages}", state.canPrevious, state.canNext, previous, next)
            }
        }
    }
}

internal fun Order.historyStatus(): Pair<String, AppStatusTone> = when (status) {
    OrderStatus.OPEN -> "Open" to AppStatusTone.SECONDARY
    OrderStatus.IN_PROCESS -> "Preparing" to AppStatusTone.ACTIVE
    OrderStatus.PROCESSED -> "Ready" to AppStatusTone.SUCCESS
    OrderStatus.DELIVERED -> "Delivered" to AppStatusTone.SUCCESS
    OrderStatus.CANCELED -> "Canceled" to AppStatusTone.SECONDARY
}

private fun Order.historyDate(): String = DateTimeFormatter.ofPattern("MMM d, HH:mm", Locale.getDefault())
    .withZone(ZoneId.systemDefault()).format(java.time.Instant.ofEpochMilli(createdAt.toEpochMilliseconds()))
