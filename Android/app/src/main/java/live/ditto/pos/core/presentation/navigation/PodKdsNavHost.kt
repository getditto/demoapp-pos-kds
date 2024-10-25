package live.ditto.pos.core.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import live.ditto.dittotoolsviewer.presentation.DittoToolsViewer
import live.ditto.pos.core.presentation.composables.screens.AdvancedSettingsScreen
import live.ditto.pos.core.presentation.composables.screens.DemoLocationSelectionScreen
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel
import live.ditto.pos.kds.presentation.composables.KdsScreen
import live.ditto.pos.pos.presentation.composables.screens.PosScreen

@Composable
fun PosKdsNavHost(
    navHostController: NavHostController,
    viewModel: CoreViewModel = hiltViewModel(),
    onSettingsUpdated: () -> Unit
) {
    NavHost(
        navController = navHostController,
        startDestination = BottomNavItem.PointOfSale.route
    ) {
        composable(BottomNavItem.PointOfSale.route) {
            PosScreen()
        }
        composable(BottomNavItem.KitchenDisplay.route) {
            KdsScreen()
        }
        composable(BottomNavItem.DemoLocationSelection.route) {
            DemoLocationSelectionScreen(
                navHostController = navHostController
            )
        }
        composable(NavigationDrawerItem.DittoToolsDrawerItem.route) {
            DittoToolsViewer(
                ditto = viewModel.requireDitto(),
                onExitTools = { navHostController.popBackStack() }
            )
        }
        composable(NavigationDrawerItem.AdvancedSettingsDrawerItem.route) {
            AdvancedSettingsScreen(
                onSettingsUpdated = {
                    navHostController.popBackStack()
                    onSettingsUpdated()
                }
            )
        }
    }
}
