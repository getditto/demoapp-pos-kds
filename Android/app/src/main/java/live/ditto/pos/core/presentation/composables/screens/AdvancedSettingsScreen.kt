package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.R
import live.ditto.pos.core.presentation.composables.CardWithTitle
import live.ditto.pos.core.presentation.composables.InnerCardWithTitle
import live.ditto.pos.core.presentation.viewmodel.SettingsViewModel

@Composable
fun AdvancedSettingsScreen(
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel(),
    onSettingsUpdated: () -> Unit = {}
) {
    val settingsState by viewModel.uiState.collectAsStateWithLifecycle()

    CardWithTitle(
        modifier = modifier.fillMaxWidth(),
        title = stringResource(R.string.advanced_settings_title)
    ) {
        InnerCardWithTitle(
            modifier = Modifier.fillMaxWidth(),
            title = stringResource(R.string.settings_location_section_header)
        ) {
            Text(
                modifier = Modifier.fillMaxWidth(),
                text = "Current location ID: ${settingsState.currentLocation?.id ?: "none"}",
                textAlign = TextAlign.Start,
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}
