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
    initialScreen: SetupScreens = SetupScreens.INITIAL_SCREEN,
    coreViewModel: CoreViewModel = hiltViewModel()
) {
    var screen by rememberSaveable {
        mutableStateOf(initialScreen)
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

            SetupScreens.CUSTOM_LOCATION -> CustomLocationScreen(
                onSaveButtonClicked = { companyName, locationName ->
                    coreViewModel.updateCustomLocation(
                        companyName = companyName,
                        locationName = locationName
                    )
                }
            )
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
                onClick = { onCustomLocationsClicked() }
            ) {
                Text(text = stringResource(R.string.button_custom_location))
            }
        }
    }
}

@Composable
private fun CustomLocationScreen(
    onSaveButtonClicked: (companyName: String, locationName: String) -> Unit
) {
    var companyName by rememberSaveable {
        mutableStateOf("")
    }
    var locationName by rememberSaveable {
        mutableStateOf("")
    }
    CardWithTitle(title = stringResource(R.string.custom_location_card_title)) {
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
            enabled = companyName.isNotBlank() && locationName.isNotBlank(),
            onClick = { onSaveButtonClicked(companyName, locationName) }
        ) {
            Text(text = stringResource(R.string.custom_location_save_button))
        }
    }
}
enum class SetupScreens {
    INITIAL_SCREEN,
    DEMO_LOCATIONS,
    CUSTOM_LOCATION
}
