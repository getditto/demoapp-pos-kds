package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import live.ditto.pos.core.data.locations.Location
import live.ditto.ui.DittoEmptyState
import live.ditto.ui.DittoRow
import live.ditto.ui.R

@Composable
fun DemoLocationsList(locations: List<Location>, modifier: Modifier = Modifier, onDemoLocationSelected: (Location) -> Unit) {
    if (locations.isEmpty()) {
        DittoEmptyState("No locations available", "Demo locations will appear here.", R.drawable.phosphor_map_pin, modifier)
    } else {
        LazyColumn(modifier.fillMaxSize().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(locations, key = { it.id }) { location ->
                DittoRow(location.name, R.drawable.phosphor_map_pin, onClick = { onDemoLocationSelected(location) })
            }
        }
    }
}
