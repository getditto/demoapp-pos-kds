package live.ditto.pos

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

@HiltAndroidApp
class DittoPOSApplication : Application() {

    @Inject lateinit var dittoRepository: DittoRepository

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        dittoRepository.startLocationsSubscription()
        applicationScope.launch {
            dittoRepository.seedAll()
            dittoRepository.runEvictionIfDue()
        }
    }
}
