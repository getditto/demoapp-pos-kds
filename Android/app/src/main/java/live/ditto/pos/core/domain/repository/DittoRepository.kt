package live.ditto.pos.core.domain.repository

import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import javax.inject.Inject

class DittoRepository @Inject constructor(private val dittoManager: DittoManager) {

    fun refreshPermissions() {
        dittoManager.requireDitto().refreshPermissions()
    }

    fun requireDitto(): Ditto {
        return dittoManager.requireDitto()
    }
}
