package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.core.presentation.composables.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.BottomNavItem
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            val bottomNavItems = listOf(
                BottomNavItem.PointOfSale,
                BottomNavItem.KitchenDisplay
            )
            val navHostController = rememberNavController()

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
    }
}