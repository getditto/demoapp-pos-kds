package live.ditto.pos.core.presentation.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import live.ditto.pos.core.presentation.composables.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.BottomNavItem
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@Composable
fun PosKdsApp() {
    val bottomNavItems = listOf(
        BottomNavItem.PointOfSale,
        BottomNavItem.KitchenDisplay
    )
    PosKdsApp(navHostController = rememberNavController(), bottomNavItems)
}

@Composable
private fun PosKdsApp(
    navHostController: NavHostController,
    bottomNavItems: List<BottomNavItem>
) {
    DittoPoSKDSDemoTheme {
        Surface {
            Scaffold(
                bottomBar = {
                    PosKdsNavigationBar(
                        bottomNavItems = bottomNavItems,
                    ) {
                        navHostController.navigate(route = it.route)
                    }
                },
                content = {
                    Surface(modifier = Modifier.padding(it)) {
                        PosKdsNavHost(navHostController = navHostController)
                    }
                }
            )
        }
    }
}