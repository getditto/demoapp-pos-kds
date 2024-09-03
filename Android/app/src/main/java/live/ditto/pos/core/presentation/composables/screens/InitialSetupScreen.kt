package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import live.ditto.pos.R
import live.ditto.pos.core.presentation.composables.CardWithTitle
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel

@Composable
fun InitialSetupScreen(
    coreViewModel: CoreViewModel = hiltViewModel()
) {
    var screen by rememberSaveable {
        mutableStateOf(SetupScreens.INITIAL_SCREEN)
    }

    Dialog(onDismissRequest = { /*TODO*/ }) {
        when (screen) {
            SetupScreens.INITIAL_SCREEN -> {
                InitialLocationsDialog(
                    onDemoLocationsClicked = {
                        coreViewModel.shouldUseDemoLocations(true)
                        screen = SetupScreens.DEMO_LOCATIONS
                    },
                    onCustomLocationsClicked = {
                        coreViewModel.shouldUseDemoLocations(false)
                        screen = SetupScreens.CUSTOM_LOCATION
                    }
                )
            }

            SetupScreens.DEMO_LOCATIONS -> {
                DemoLocationsList(
                    onDemoLocationSelected = {
                        coreViewModel.updateCurrentLocation(locationId = it.id)
                    }
                )
            }

            SetupScreens.CUSTOM_LOCATION -> CustomLocationScreen()
        }
    }
}

@Composable
private fun InitialLocationsDialog(
    onDemoLocationsClicked: () -> Unit,
    onCustomLocationsClicked: () -> Unit
) {
    CardWithTitle(title = stringResource(R.string.store_locations_options_card_title)) {
        Text(text = stringResource(R.string.custom_location_card_description))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(
                8.dp,
                alignment = Alignment.CenterHorizontally
            )
        ) {
            Button(onClick = { onDemoLocationsClicked() }) {
                Text(text = stringResource(R.string.button_demo_locations))
            }
            Button(
                enabled = false,
                onClick = { onCustomLocationsClicked() }
            ) {
                Text(text = stringResource(R.string.button_custom_location))
            }
        }
    }
}

@Composable
private fun CustomLocationScreen() {
    CardWithTitle(title = stringResource(R.string.custom_location_card_title)) {
        var companyName by rememberSaveable {
            mutableStateOf("")
        }
        var locationName by rememberSaveable {
            mutableStateOf("")
        }
        TextField(
            modifier = Modifier.fillMaxWidth(),
            label = { Text(text = stringResource(R.string.custom_location_company_name)) },
            value = companyName,
            onValueChange = { companyName = it }
        )
        TextField(
            modifier = Modifier.fillMaxWidth(),
            label = { Text(text = stringResource(R.string.custom_location_location_name_label)) },
            value = locationName,
            onValueChange = { locationName = it }
        )

        Button(
            onClick = { /*TODO*/ }
        ) {
            Text(text = stringResource(R.string.custom_location_save_button))
        }
    }
}

private enum class SetupScreens {
    INITIAL_SCREEN,
    DEMO_LOCATIONS,
    CUSTOM_LOCATION
}
