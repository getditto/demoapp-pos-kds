package live.ditto.pos.core.domain.usecase

import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class IsUsingDemoLocationsUseCase @Inject constructor(
    private val appSettings: AppSettings
) {

    suspend operator fun invoke(): Boolean {
        return appSettings.isUsingDemoLocations() ?: false
    }
}
