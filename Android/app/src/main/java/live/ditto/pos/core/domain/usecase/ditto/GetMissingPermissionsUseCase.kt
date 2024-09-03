package live.ditto.pos.core.domain.usecase.ditto

import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class GetMissingPermissionsUseCase @Inject constructor(
    private val dittoRepository: DittoRepository
) {

    operator fun invoke(): Array<String> {
        return dittoRepository.getMissingPermissions()
    }
}
