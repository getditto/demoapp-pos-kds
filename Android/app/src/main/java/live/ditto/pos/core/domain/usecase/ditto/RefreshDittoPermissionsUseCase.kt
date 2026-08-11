package live.ditto.pos.core.domain.usecase.ditto

import live.ditto.ditto_wrapper.DittoManager
import javax.inject.Inject

class RefreshDittoPermissionsUseCase @Inject constructor(private val dittoManager: DittoManager) {

    operator fun invoke() {
        dittoManager.refreshPermissions()
    }
}
