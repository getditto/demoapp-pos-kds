package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class IsUsingDemoLocationsUseCase @Inject constructor(
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(): Boolean {
        return coreRepository.isUsingDemoLocations() ?: false
    }
}
