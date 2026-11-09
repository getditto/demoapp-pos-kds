package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ditto.kotlin.Ditto
import com.ditto.tools.toolsviewer.DittoToolsViewer
import live.ditto.pos.BuildConfig
import live.ditto.pos.LocalActivity
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.composables.navigation.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.core.presentation.viewmodel.MainViewModel
import live.ditto.pos.kds.presentation.composables.KdsScreen
import live.ditto.pos.pos.presentation.composables.screens.PosScreen
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.DittoHeader
import live.ditto.ui.DittoIcon
import live.ditto.ui.R

@Composable
fun PosKdsApp(viewModel: MainViewModel = hiltViewModel(LocalActivity.current)) {
    val state by viewModel.uiState.collectAsStateWithLifecycle(minActiveState = Lifecycle.State.RESUMED)
    val configuration by viewModel.configuration.collectAsStateWithLifecycle(minActiveState = Lifecycle.State.RESUMED)
    val appearance by viewModel.appearance.collectAsStateWithLifecycle()
    PosKdsShell(
        state = state, needsLocation = configuration == AppConfigurationState.LOCATION_NEEDED,
        appearance = appearance ?: AppAppearance.SYSTEM,
        version = BuildConfig.VERSION_NAME, build = BuildConfig.VERSION_CODE.toString(), sdkVersion = Ditto.VERSION,
        onAppearance = viewModel::setAppearance, onLocation = viewModel::updateCurrentLocation,
        pos = { PosScreen() }, kds = { KdsScreen() },
        tools = { onExit -> DittoToolsViewer(ditto = viewModel.requireDitto(), onExitTools = onExit) }
    )
}

@Composable
fun PosKdsShell(
    state: AppState,
    needsLocation: Boolean,
    appearance: AppAppearance,
    version: String,
    build: String,
    sdkVersion: String,
    onAppearance: (AppAppearance) -> Unit,
    onLocation: (String, () -> Unit) -> Unit,
    pos: @Composable () -> Unit,
    kds: @Composable () -> Unit,
    tools: @Composable (() -> Unit) -> Unit,
    controller: NavHostController = rememberNavController(),
    startDestination: String = "pos"
) {
    val entry by controller.currentBackStackEntryAsState()
    val route = entry?.destination?.route
    val onTools = route == "settings/tools"
    val selecting = route == "settings/locations"
    val title = if (needsLocation || selecting) {
        "Select location"
    } else {
        when (route) {
            "kds" -> "Kitchen"
            "settings" -> "Settings"
            else -> "POS"
        }
    }
    Scaffold(
        bottomBar = {
            if (!needsLocation && !onTools) {
                PosKdsNavigationBar(selectedRoute = route) { item ->
                    controller.navigate(item.route) {
                        popUpTo(controller.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            }
        }
    ) { padding ->
        Surface(Modifier.padding(padding), color = MaterialTheme.colorScheme.background) {
            Column {
                if (!onTools) {
                    if (selecting) {
                        IconButton(onClick = { controller.popBackStack() }) { DittoIcon(R.drawable.phosphor_arrow_left, description = "Back") }
                    }
                    DittoHeader(title, location = state.currentLocationName, tablet = LocalConfiguration.current.screenWidthDp >= 600)
                }
                if (needsLocation) {
                    if (state.isLoading) {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                    } else {
                        DemoLocationsList(state.locations, onDemoLocationSelected = { onLocation(it.id) {} })
                    }
                } else {
                    PosKdsNavHost(
                        controller, state, appearance, version, build, sdkVersion,
                        onAppearance, onLocation, pos, kds, tools, startDestination
                    )
                }
            }
        }
    }
}
