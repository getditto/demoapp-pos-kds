package live.ditto.pos.core.domain.usecase

import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class SetCurrentLocationUseCase @Inject constructor(
    private val appSettings: AppSettings
) {

    // Persist the chosen locationId; DittoRepository observes the same flow
    // and (re-)configures the sync group + orders/sale_items subscriptions for
    // the new value.
    suspend operator fun invoke(locationId: String) {
        appSettings.setLocationId(locationId = locationId)
    }
}
