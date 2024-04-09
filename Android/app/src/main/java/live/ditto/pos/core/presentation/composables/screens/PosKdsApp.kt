package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
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

@OptIn(ExperimentalMaterial3Api::class)
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
                        bottomNavItems = bottomNavItems
                    ) {
                        navHostController.navigate(route = it.route)
                    }
                },
                topBar = {
                    CenterAlignedTopAppBar(
                        title = {
                            Text(text = "McDitto's")
                        },
                        colors = TopAppBarDefaults
                            .centerAlignedTopAppBarColors(containerColor = Color.LightGray)
                    )
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

@Preview
@Composable
private fun PosKdsAppPreview() {
    PosKdsApp()
}
