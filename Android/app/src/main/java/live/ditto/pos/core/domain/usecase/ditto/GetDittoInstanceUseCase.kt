package live.ditto.pos.core.domain.usecase.ditto

import live.ditto.Ditto
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class GetDittoInstanceUseCase @Inject constructor(private val dittoRepository: DittoRepository) {

    operator fun invoke(): Ditto = dittoRepository.requireDitto()
}
