package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import live.ditto.pos.core.data.locations.Location
import live.ditto.ui.AppEmptyState
import live.ditto.ui.AppLayout
import live.ditto.ui.AppRow
import live.ditto.ui.R

@Composable
fun DemoLocationsList(locations: List<Location>, modifier: Modifier = Modifier, onDemoLocationSelected: (Location) -> Unit) {
    if (locations.isEmpty()) {
        AppEmptyState("No locations available", "Demo locations will appear here.", R.drawable.phosphor_map_pin, modifier)
    } else {
        LazyColumn(modifier.fillMaxSize().padding(horizontal = AppLayout.padding), verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
            items(locations, key = { it.id }) { location ->
                AppRow(location.name, R.drawable.phosphor_map_pin, onClick = { onDemoLocationSelected(location) }, outlined = true)
            }
        }
    }
}
