package live.ditto.pos.core.presentation.navigation

import androidx.annotation.DrawableRes
import live.ditto.ui.R

sealed class BottomNavItem(val route: String, val label: String, @DrawableRes val icon: Int) {
    data object PointOfSale : BottomNavItem("pos", "POS", R.drawable.phosphor_cash_register)
    data object KitchenDisplay : BottomNavItem("kds", "KDS", R.drawable.phosphor_cooking_pot)
    data object Settings : BottomNavItem("settings", "Settings", R.drawable.phosphor_gear)
}
