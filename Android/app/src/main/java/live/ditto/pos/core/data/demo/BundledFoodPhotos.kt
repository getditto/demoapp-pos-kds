package live.ditto.pos.core.data.demo

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import live.ditto.pos.R
import live.ditto.pos.core.data.DocumentID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BundledFoodPhotos @Inject constructor(@ApplicationContext private val context: Context) {
    internal fun bytes(id: DocumentID): ByteArray? = resource(id)?.let { resource ->
        context.resources.openRawResource(resource).use { it.readBytes() }
    }

    private fun resource(id: DocumentID): Int? {
        if (!SaleItemSeed.contains(id)) return null
        return resources[id.id]
    }

    companion object {
        private val resources = mapOf(
            "00001" to R.raw.stock_burger,
            "00002" to R.raw.stock_burrito,
            "00003" to R.raw.stock_chicken,
            "00004" to R.raw.stock_chips,
            "00005" to R.raw.stock_coffee,
            "00006" to R.raw.stock_cookies,
            "00007" to R.raw.stock_corn_on_cob,
            "00008" to R.raw.stock_fries,
            "00009" to R.raw.stock_fruit_salad,
            "00010" to R.raw.stock_gumbo,
            "00011" to R.raw.stock_ice_cream,
            "00012" to R.raw.stock_milk,
            "00013" to R.raw.stock_onion_rings,
            "00014" to R.raw.stock_pancakes,
            "00015" to R.raw.stock_pie,
            "00016" to R.raw.stock_salad,
            "00017" to R.raw.stock_sandwich,
            "00018" to R.raw.stock_soft_drink,
            "00019" to R.raw.stock_tacos,
            "00020" to R.raw.stock_veggies
        )
    }
}
