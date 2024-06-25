package live.ditto.pos.core.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import live.ditto.pos.kds.presentation.composables.KdsScreen
import live.ditto.pos.pos.presentation.composables.screens.PosScreen

@Composable
fun PosKdsNavHost(navHostController: NavHostController) {
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
    }
}
