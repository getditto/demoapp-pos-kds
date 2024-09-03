package live.ditto.pos

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

@HiltAndroidApp
class DittoPOSApplication : Application() {

    @Inject lateinit var dittoRepository: DittoRepository

    override fun onCreate() {
        super.onCreate()
        dittoRepository.startLocationSubscription()
    }
}
