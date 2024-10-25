package live.ditto.pos.core.presentation.composables.screens

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
        SettingsSection(sectionName = R.string.settings_location_section_header) {
            TextSettingsItem(text = "Current location ID: ${settingsState.currentLocation?.id}")
            HorizontalDivider(modifier = Modifier.fillMaxWidth())
            SwitchSettingsItem(
                name = R.string.settings_use_demo_locations_name,
                description = R.string.settings_use_demo_locations_description,
                checkedState = settingsState.isUsingDemoLocations,
                onToggleChanged = {
                    viewModel.shouldUseDemoLocations(it)
                    onSettingsUpdated()
                }
            )
        }
    }
}

@Composable
private fun TextSettingsItem(
    text: String
) {
    Text(
        modifier = Modifier.fillMaxWidth(),
        text = text,
        textAlign = TextAlign.Start,
        style = MaterialTheme.typography.bodySmall
    )
}

@Composable
private fun SettingsSection(
    modifier: Modifier = Modifier,
    @StringRes sectionName: Int,
    content: @Composable ColumnScope.() -> Unit
) {
    InnerCardWithTitle(
        modifier = modifier.fillMaxWidth(),
        title = stringResource(sectionName)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            content()
        }
    }
}

@Composable
private fun SwitchSettingsItem(
    @StringRes name: Int,
    @StringRes description: Int? = null,
    checkedState: Boolean,
    onToggleChanged: (state: Boolean) -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column {
                        Text(
                            text = stringResource(id = name),
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Start
                        )
                        description?.let {
                            Text(
                                text = stringResource(id = it),
                                style = MaterialTheme.typography.bodySmall,
                                textAlign = TextAlign.Start
                            )
                        }
                    }
                    Spacer(modifier = Modifier.weight(1f))
                    Switch(checked = checkedState, onCheckedChange = {
                        onToggleChanged(it)
                    })
                }
            }
        }
    }
}
