package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class IsSetupValidUseCase @Inject constructor(private val coreRepository: CoreRepository) {

    suspend operator fun invoke(): Boolean {
        val locationId = coreRepository.locationId()
        return locationId.isNotEmpty()
    }
}
