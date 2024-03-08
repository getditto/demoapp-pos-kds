package live.ditto.pos.core.presentation.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PointOfSale
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.outlined.PointOfSale
import androidx.compose.material.icons.outlined.Receipt
import androidx.compose.ui.graphics.vector.ImageVector
import live.ditto.pos.R

sealed class BottomNavItem(
    val route: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    @StringRes val label: Int
) {
    data object PointOfSale : BottomNavItem(
        route = "pos",
        selectedIcon = Icons.Filled.PointOfSale,
        unselectedIcon = Icons.Outlined.PointOfSale,
        label = R.string.navigation_label_pos
    )

    data object KitchenDisplay : BottomNavItem(
        route = "kds",
        selectedIcon = Icons.Filled.Receipt,
        unselectedIcon = Icons.Outlined.Receipt,
        label = R.string.navigation_label_kds
    )
}