package live.ditto.pos.kds.presentation.composables

import android.text.format.DateUtils
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import kotlinx.coroutines.delay
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.presentation.composables.LocationHeader
import live.ditto.pos.kds.KitchenBoardViewModel
import live.ditto.pos.kds.KitchenTicketViewModel
import live.ditto.pos.kds.TicketItemUi
import live.ditto.ui.AppColors
import live.ditto.ui.AppEmptyState
import live.ditto.ui.AppLayout
import live.ditto.ui.AppWell
import live.ditto.ui.BrandTheme
import kotlin.time.Clock

@Composable
fun TicketGrid(ticketItems: List<TicketItemUi>, onAdvance: (orderId: String) -> Unit) {
    val now by produceState(System.currentTimeMillis()) {
        while (true) {
            value = System.currentTimeMillis()
            delay(DateUtils.MINUTE_IN_MILLIS)
        }
    }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val viewModel = KitchenBoardViewModel(ticketItems, maxWidth.value)
        Column(Modifier.fillMaxSize().padding(viewModel.contentPadding), verticalArrangement = Arrangement.spacedBy(viewModel.headerSpacing)) {
            Row(Modifier.fillMaxWidth().heightIn(min = AppLayout.compactRowHeight), horizontalArrangement = if (viewModel.expanded) Arrangement.spacedBy(AppLayout.sectionGap) else Arrangement.SpaceBetween) {
                StageCount(viewModel.countTitle("Preparing", viewModel.preparing.size), viewModel, Modifier.then(if (viewModel.expanded) Modifier.weight(1f) else Modifier))
                StageCount(viewModel.countTitle("Ready", viewModel.ready.size), viewModel, Modifier.then(if (viewModel.expanded) Modifier.weight(1f) else Modifier), ready = true)
            }
            if (viewModel.isEmpty) {
                AppEmptyState("No active orders", "Orders with items appear here.", live.ditto.ui.R.drawable.phosphor_check_circle, style = live.ditto.ui.AppEmptyStateStyle.SUCCESS)
            } else if (viewModel.expanded) {
                Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(AppLayout.sectionGap)) {
                    StageColumn(viewModel.preparing, viewModel.showPreparingWell, "No orders preparing", now, onAdvance, Modifier.weight(1f))
                    StageColumn(viewModel.ready, viewModel.showReadyWell, "No orders ready", now, onAdvance, Modifier.weight(1f))
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
                    items(viewModel.phoneTickets, key = { it.orderId }) { ticket -> TicketItem(ticket, now, onAdvance) }
                }
            }
        }
    }
}

@Composable
private fun StageCount(title: String, viewModel: KitchenBoardViewModel, modifier: Modifier = Modifier, ready: Boolean = false) {
    Text(title, modifier.semantics { heading() }, style = viewModel.headerStyle, color = if (ready) AppColors.success else MaterialTheme.colorScheme.onSurface)
}

@Composable
private fun StageColumn(tickets: List<TicketItemUi>, showWell: Boolean, emptyMessage: String, now: Long, onAdvance: (String) -> Unit, modifier: Modifier) {
    LazyColumn(modifier, verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
        if (showWell) {
            item { AppWell { Text(emptyMessage, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) } }
        } else {
            items(tickets, key = { it.orderId }) { ticket -> TicketItem(ticket, now, onAdvance) }
        }
    }
}

@Composable
private fun TicketItem(ticket: TicketItemUi, now: Long, onAdvance: (String) -> Unit) {
    val viewModel = KitchenTicketViewModel(ticket, now)
    KitchenTicketCard(viewModel, onAdvance = { onAdvance(ticket.orderId) })
}

@Preview(widthDp = 1024, heightDp = 748)
@Preview(widthDp = 393, heightDp = 800)
@Composable
private fun KitchenPreview() {
    BrandTheme {
        Column {
            LocationHeader("Kitchen display", location = "Ham's Burgers", expanded = false)
            TicketGrid(listOf(TicketItemUi(Clock.System.now(), "1042ABCD", hashMapOf("Burger" to 2, "Coffee" to 1), false, OrderStatus.IN_PROCESS, "1042ABCD"))) {}
        }
    }
}
