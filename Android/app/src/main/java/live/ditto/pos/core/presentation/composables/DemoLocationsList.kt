package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
            Text(stringResource(R.string.location_selection_empty), modifier = Modifier.padding(vertical = 16.dp), style = MaterialTheme.typography.bodyLarge)
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
