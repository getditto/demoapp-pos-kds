package live.ditto.pos.core.presentation.navigation

import androidx.annotation.StringRes
import live.ditto.pos.R

sealed class NavigationDrawerItem(
    @StringRes val label: Int,
    val route: String
) {
    data object DittoToolsDrawerItem : NavigationDrawerItem(
        label = R.string.navigation_drawer_label_ditto_tools,
        route = "ditto_tools"
    )
}
