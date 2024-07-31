package live.ditto.pos.core.domain.repository

import kotlinx.coroutines.flow.Flow
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.ditto_wrapper.DittoProperty
import live.ditto.ditto_wrapper.DittoStoreManager
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DittoRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val dittoStoreManager: DittoStoreManager
) {

    fun refreshPermissions() {
        dittoManager.requireDitto().refreshPermissions()
    }

    fun requireDitto(): Ditto {
        return dittoManager.requireDitto()
    }

    fun insertDefaultLocations() {
        TODO("Not yet implemented")
    }

    fun subscribe(query: String, args: Map<String, String> = emptyMap()): Flow<List<DittoProperty>> {
        return dittoStoreManager.subscribe(query, args)
    }

    fun getMissingPermissions(): Array<String> {
        return dittoManager.missingPermissions()
    }
}
