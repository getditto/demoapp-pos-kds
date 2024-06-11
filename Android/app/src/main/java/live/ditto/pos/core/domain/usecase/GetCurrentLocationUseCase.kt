package live.ditto.pos.core.domain.usecase

import kotlinx.coroutines.flow.last
import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(private val coreRepository: CoreRepository) {

    suspend operator fun invoke(): String {
        return coreRepository.locationId().last() ?: ""
    }
}
