package live.ditto.pos.pos.domain.usecase

import java.util.UUID
import javax.inject.Inject

class GenerateOrderIdUseCase @Inject constructor() {

    operator fun invoke(currentOrderId: String): String {
        return currentOrderId.ifEmpty {
            UUID.randomUUID().toString()
        }
    }
}
