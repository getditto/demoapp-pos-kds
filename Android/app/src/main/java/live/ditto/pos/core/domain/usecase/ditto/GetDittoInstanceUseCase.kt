package live.ditto.pos.core.domain.usecase.ditto

import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import javax.inject.Inject

class GetDittoInstanceUseCase @Inject constructor(private val dittoManager: DittoManager) {

    operator fun invoke(): Ditto = dittoManager.requireDitto()
}
