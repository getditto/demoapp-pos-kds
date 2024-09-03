package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import live.ditto.pos.R
import live.ditto.pos.core.data.demoLocations
import live.ditto.pos.core.data.locations.Location

@Composable
fun DemoLocationsList(
    modifier: Modifier = Modifier,
    onDemoLocationSelected: (Location) -> Unit
) {
    CardWithTitle(
        modifier = modifier,
        title = stringResource(R.string.location_selection_title)
    ) {
        demoLocations.forEach {
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = { onDemoLocationSelected(it) }
            ) {
                Text(text = it.name)
            }
        }
    }
}
