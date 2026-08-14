package live.ditto.pos

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.repository.LocationsRepository
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.core.data.repository.SaleItemsRepository
import javax.inject.Inject

@HiltAndroidApp
class DittoPOSApplication : Application() {

    @Inject lateinit var dittoManager: DittoManager

    @Inject lateinit var locationsRepository: LocationsRepository

    @Inject lateinit var ordersRepository: OrdersRepository

    // Injected here even though we don't reference it directly — its init
    // block sets up the location-id flow collector that drives the sale_items
    // subscription on app start.
    @Suppress("unused")
    @Inject
    lateinit var saleItemsRepository: SaleItemsRepository

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        locationsRepository.startSubscription()
        applicationScope.launch {
            DemoSeeder(dittoManager.requireDitto()).seedAll()
            ordersRepository.runEvictionIfDue()
        }
    }
}
