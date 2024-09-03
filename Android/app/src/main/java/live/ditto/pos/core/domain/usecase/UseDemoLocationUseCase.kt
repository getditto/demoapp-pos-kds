package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class UseDemoLocationUseCase @Inject constructor(private val repository: CoreRepository) {

    suspend operator fun invoke(shouldUseDemoLocations: Boolean) {
        repository.shouldUseDemoLocations(useDemoLocations = shouldUseDemoLocations)
    }
}
