package live.ditto.pos.core.presentation.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Build
import androidx.compose.ui.graphics.vector.ImageVector
import live.ditto.pos.R

sealed class NavigationDrawerItem(
    @StringRes val label: Int,
    val route: String,
    val icon: ImageVector
) {
    data object DittoToolsDrawerItem : NavigationDrawerItem(
        label = R.string.navigation_drawer_label_ditto_tools,
        route = "ditto_tools",
        icon = Icons.Outlined.Build
    )
}
