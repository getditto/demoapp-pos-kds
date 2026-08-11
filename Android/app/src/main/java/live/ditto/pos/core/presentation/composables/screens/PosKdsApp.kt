package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import live.ditto.pos.LocalActivity
import live.ditto.pos.R
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.core.presentation.composables.navigation.PosKDSNavigationDrawer
import live.ditto.pos.core.presentation.composables.navigation.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.NavigationDrawerItem
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.core.presentation.viewmodel.MainViewModel

@Composable
fun PosKdsApp(
    viewModel: MainViewModel = hiltViewModel(LocalActivity.current)
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    when (state.appConfigurationState) {
        AppConfigurationState.VALID -> {
            PosKdsApp(
                navHostController = rememberNavController(),
                state = state
            )
        }

        AppConfigurationState.LOCATION_NEEDED -> {
            InitialSetupScreen()
        }
    }
}

@Composable
private fun PosKdsApp(
    navHostController: NavHostController,
    state: AppState
) {
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val currentDestination by navHostController.currentBackStackEntryAsState()
    val onDittoTools = currentDestination?.destination?.route == NavigationDrawerItem.DittoToolsDrawerItem.route

    Surface {
        PosKDSNavigationDrawer(
            navController = navHostController,
            drawerState = drawerState,
            scope = scope,
            gesturesEnabled = !onDittoTools
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
                }
            )
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun PosKDSScaffold(
    navHostController: NavHostController,
    state: AppState,
    onNavigationClicked: () -> Unit
) {
    Scaffold(
        bottomBar = {
            PosKdsNavigationBar(
                onItemClick = {
                    // Ditto Tools is a drawer destination, not a tab — pop it
                    // explicitly so DittoToolsViewer is fully cleared before
                    // the standard tab navigation runs.
                    if (navHostController.currentDestination?.route == NavigationDrawerItem.DittoToolsDrawerItem.route) {
                        navHostController.popBackStack()
                    }
                    // Single-top + restoreState so each tab reuses its
                    // NavBackStackEntry (and its ViewModels' Ditto observers).
                    navHostController.navigate(route = it.route) {
                        popUpTo(navHostController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        },
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(text = state.currentLocationName)
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    titleContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                ),
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
                    navHostController = navHostController
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
