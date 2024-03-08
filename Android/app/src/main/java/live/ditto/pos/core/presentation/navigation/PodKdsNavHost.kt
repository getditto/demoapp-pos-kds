package live.ditto.pos.core.presentation.navigation

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.pos.presentation.composables.SaleItemsGrid

@Composable
fun PosKdsNavHost(navHostController: NavHostController) {
    NavHost(
        navController = navHostController,
        startDestination = BottomNavItem.PointOfSale.route
    ) {
        composable(BottomNavItem.PointOfSale.route) {
            SaleItemsGrid(saleItems = demoMenuData)
        }
        composable(BottomNavItem.KitchenDisplay.route) {
            Text(text = "Kitchen display screen")
        }
    }
}