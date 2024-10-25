package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import live.ditto.pos.LocalActivity
import live.ditto.pos.R
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.core.presentation.composables.navigation.PosKDSNavigationDrawer
import live.ditto.pos.core.presentation.composables.navigation.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@Composable
fun PosKdsApp(
    viewModel: CoreViewModel = hiltViewModel(LocalActivity.current)
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    val scope = rememberCoroutineScope()

    when (state.appConfigurationState) {
        AppConfigurationState.VALID -> {
            PosKdsApp(
                navHostController = rememberNavController(),
                state = state,
                onSettingsUpdated = {
                    scope.launch {
                        viewModel.updateAppState()
                    }
                }
            )
        }

        AppConfigurationState.LOCATION_NEEDED -> {
            val initialSetupScreen = if (state.isDemoLocationsMode) {
                SetupScreens.DEMO_LOCATIONS
            } else {
                SetupScreens.CUSTOM_LOCATION
            }
            InitialSetupScreen(initialScreen = initialSetupScreen)
        }

        AppConfigurationState.DEMO_OR_CUSTOM_LOCATION_NEEDED -> InitialSetupScreen()
    }
}

@Composable
private fun PosKdsApp(
    navHostController: NavHostController,
    state: AppState,
    onSettingsUpdated: () -> Unit
) {
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    DittoPoSKDSDemoTheme {
        Surface {
            PosKDSNavigationDrawer(
                navController = navHostController,
                drawerState = drawerState,
                scope = scope
            ) {
                PosKDSScaffold(
                    navHostController = navHostController,
                    state = state,
                    onNavigationClicked = {
                        scope.launch {
                            drawerState.apply {
                                if (isClosed) open() else close()
                            }
                        }
                    },
                    onSettingsUpdated = onSettingsUpdated
                )
            }
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun PosKDSScaffold(
    navHostController: NavHostController,
    state: AppState,
    onNavigationClicked: () -> Unit,
    onSettingsUpdated: () -> Unit
) {
    Scaffold(
        bottomBar = {
            PosKdsNavigationBar(
                showDemoLocationsNavItem = state.isDemoLocationsMode,
                onItemClick = {
                    navHostController.navigate(route = it.route)
                }
            )
        },
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(text = state.currentLocationName)
                },
                colors = TopAppBarDefaults
                    .centerAlignedTopAppBarColors(containerColor = Color.LightGray),
                navigationIcon = {
                    IconButton(onClick = { onNavigationClicked() }) {
                        Icon(
                            imageVector = Icons.Filled.Menu,
                            contentDescription = stringResource(R.string.hamburger_menu)
                        )
                    }
                }
            )
        },
        content = {
            Surface(modifier = Modifier.padding(it)) {
                PosKdsNavHost(
                    navHostController = navHostController,
                    onSettingsUpdated = onSettingsUpdated
                )
            }
        }
    )
}

@Preview
@Composable
private fun PosKdsAppPreview() {
    PosKdsApp()
}
