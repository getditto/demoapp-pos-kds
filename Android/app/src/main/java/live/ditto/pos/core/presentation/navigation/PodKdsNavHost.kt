package live.ditto.pos.core.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.settings.AppAppearance
import live.ditto.pos.settings.presentation.SettingsScreen

@Composable
fun PosKdsNavHost(
    navHostController: NavHostController,
    state: live.ditto.pos.core.presentation.viewmodel.AppState,
    appearance: AppAppearance,
    version: String,
    build: String,
    sdkVersion: String,
    onAppearance: (AppAppearance) -> Unit,
    onLocation: (String, () -> Unit) -> Unit,
    pos: @Composable () -> Unit,
    kds: @Composable () -> Unit,
    tools: @Composable (() -> Unit) -> Unit,
    startDestination: String
) {
    NavHost(navController = navHostController, startDestination = startDestination) {
        composable(BottomNavItem.PointOfSale.route) { pos() }
        composable(BottomNavItem.KitchenDisplay.route) { kds() }
        composable(BottomNavItem.Settings.route) {
            SettingsScreen(
                location = state.currentLocationName,
                appearance = appearance,
                version = version,
                build = build,
                sdkVersion = sdkVersion,
                onAppearance = onAppearance,
                onLocation = { navHostController.navigate("settings/locations") },
                onTools = { navHostController.navigate("settings/tools") }
            )
        }
        composable("settings/locations") {
            DemoLocationsList(state.locations, onDemoLocationSelected = { location ->
                val changed = location.id != state.currentLocationId
                onLocation(location.id) {
                    navHostController.popBackStack()
                    if (changed) {
                        navHostController.navigate(BottomNavItem.PointOfSale.route) {
                            popUpTo(navHostController.graph.startDestinationId) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                }
            })
        }
        composable("settings/tools") {
            tools { navHostController.popBackStack() }
        }
    }
}
