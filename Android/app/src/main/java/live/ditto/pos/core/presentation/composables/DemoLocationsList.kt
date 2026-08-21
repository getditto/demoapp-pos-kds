package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.pos.core.data.locations.Location

@Composable
fun DemoLocationsList(
    locations: List<Location>,
    modifier: Modifier = Modifier,
    onDemoLocationSelected: (Location) -> Unit
) {
    CardWithTitle(
        modifier = modifier,
        title = stringResource(R.string.location_selection_title)
    ) {
        if (locations.isEmpty()) {
            // The setup dialog can't be dismissed, so an empty card would be
            // indistinguishable from a hang. Locations are seeded into the
            // local store on launch, so this shows only until that lands.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp))
                Text(
                    text = stringResource(R.string.location_selection_loading),
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        } else {
            locations.forEach { location ->
                Button(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { onDemoLocationSelected(location) }
                ) {
                    Text(text = location.name)
                }
            }
        }
    }
}
