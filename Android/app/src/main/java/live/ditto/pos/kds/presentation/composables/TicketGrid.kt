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
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.kds.TicketItemUi
import live.ditto.ui.DittoColors
import live.ditto.ui.DittoEmptyState
import live.ditto.ui.DittoHeader
import live.ditto.ui.DittoTheme
import live.ditto.ui.DittoTicket
import live.ditto.ui.DittoWell
import kotlin.time.Clock

@Composable
fun TicketGrid(ticketItems: List<TicketItemUi>, onAdvance: (orderId: String) -> Unit) {
    val now by produceState(System.currentTimeMillis()) {
        while (true) {
            value = System.currentTimeMillis()
            delay(DateUtils.MINUTE_IN_MILLIS)
        }
    }
    val preparing = ticketItems.filter { it.orderStatus == OrderStatus.IN_PROCESS }
    val ready = ticketItems.filter { it.orderStatus == OrderStatus.PROCESSED }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val tablet = maxWidth >= 600.dp
        Column(Modifier.fillMaxSize().padding(if (tablet) 24.dp else 16.dp), verticalArrangement = Arrangement.spacedBy(if (tablet) 16.dp else 12.dp)) {
            Row(Modifier.fillMaxWidth().heightIn(min = 32.dp), horizontalArrangement = if (tablet) Arrangement.spacedBy(24.dp) else Arrangement.SpaceBetween) {
                StageCount("Preparing", preparing.size, tablet, Modifier.then(if (tablet) Modifier.weight(1f) else Modifier))
                StageCount("Ready", ready.size, tablet, Modifier.then(if (tablet) Modifier.weight(1f) else Modifier), ready = true)
            }
            if (preparing.isEmpty() && ready.isEmpty()) {
                DittoEmptyState("No active orders", "Orders with items appear here.", live.ditto.ui.R.drawable.phosphor_check_circle, prominent = true)
            } else if (tablet) {
                Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                    StageColumn(preparing, "No orders preparing", now, onAdvance, Modifier.weight(1f))
                    StageColumn(ready, "No orders ready", now, onAdvance, Modifier.weight(1f))
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(preparing + ready, key = { it.orderId }) { ticket -> TicketItem(ticket, now, onAdvance) }
                }
            }
        }
    }
}

@Composable
private fun StageCount(title: String, count: Int, tablet: Boolean, modifier: Modifier = Modifier, ready: Boolean = false) {
    Text(if (tablet) "$title · $count" else "$title $count", modifier.semantics { heading() }, style = if (tablet) MaterialTheme.typography.titleLarge else MaterialTheme.typography.bodyMedium, color = if (ready) DittoColors.success else MaterialTheme.colorScheme.onSurface)
}

@Composable
private fun StageColumn(tickets: List<TicketItemUi>, emptyMessage: String, now: Long, onAdvance: (String) -> Unit, modifier: Modifier) {
    LazyColumn(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (tickets.isEmpty()) {
            item { DittoWell { Text(emptyMessage, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) } }
        } else {
            items(tickets, key = { it.orderId }) { ticket -> TicketItem(ticket, now, onAdvance) }
        }
    }
}

@Composable
private fun TicketItem(ticket: TicketItemUi, now: Long, onAdvance: (String) -> Unit) {
    DittoTicket(
        title = "#${ticket.shortOrderId}",
        lines = ticket.items.toSortedMap().map { (name, count) -> "$count × $name" },
        isPaid = ticket.isPaid,
        elapsed = DateUtils.getRelativeTimeSpanString(ticket.createdAt.toEpochMilliseconds(), now, DateUtils.MINUTE_IN_MILLIS, DateUtils.FORMAT_ABBREV_RELATIVE).toString(),
        isReady = ticket.orderStatus == OrderStatus.PROCESSED,
        onAdvance = { onAdvance(ticket.orderId) }
    )
}

@Preview(widthDp = 1024, heightDp = 748)
@Preview(widthDp = 393, heightDp = 800)
@Composable
private fun KitchenPreview() {
    DittoTheme {
        Column {
            DittoHeader("Kitchen display", location = "Ham's Burgers")
            TicketGrid(listOf(TicketItemUi(Clock.System.now(), "1042ABCD", hashMapOf("Burger" to 2, "Coffee" to 1), false, OrderStatus.IN_PROCESS, "1042ABCD"))) {}
        }
    }
}
