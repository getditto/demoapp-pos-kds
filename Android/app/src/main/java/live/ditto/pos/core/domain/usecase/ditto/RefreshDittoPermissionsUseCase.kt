package live.ditto.pos.core.domain.usecase.ditto

import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class RefreshDittoPermissionsUseCase @Inject constructor(private val dittoRepository: DittoRepository) {

    operator fun invoke() {
        dittoRepository.refreshPermissions()
    }
}
