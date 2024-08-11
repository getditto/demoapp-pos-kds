package live.ditto.pos.pos.domain.usecase

import kotlinx.datetime.Clock
import javax.inject.Inject

class GetCurrentTimeStringUseCase @Inject constructor() {

    operator fun invoke(): String {
        return Clock.System.now().toString()
    }
}
