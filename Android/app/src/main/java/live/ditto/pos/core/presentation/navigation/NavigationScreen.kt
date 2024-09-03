package live.ditto.pos.core.presentation.navigation

open class NavigationScreen(
    val route: String
) {
    data object InitialSetupScreen : NavigationScreen(
        route = "initial_setup_screen"
    )
}
