package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import java.util.UUID
import javax.inject.Inject

class GenerateOrderIdUseCase @Inject constructor(
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(): String {
        val currentOrderId = coreRepository.currentOrderId()
        return currentOrderId.ifEmpty {
            val newId = UUID.randomUUID().toString()
            coreRepository.setCurrentOrderId(newId)
            return newId
        }
    }
}
