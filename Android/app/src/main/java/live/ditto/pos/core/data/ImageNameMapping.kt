package live.ditto.pos.core.data

import live.ditto.pos.R

// Maps the canonical wire imageName (snake_case) to an Android drawable id.
object ImageNameMapping {
    private val canonicalToResource: Map<String, Int> = mapOf(
        "burger" to R.drawable.burger,
        "burrito" to R.drawable.burrito,
        "chicken" to R.drawable.chicken,
        "chips" to R.drawable.chips,
        "coffee" to R.drawable.coffee,
        "cookies" to R.drawable.cookies,
        "corn" to R.drawable.corn_on_cob,
        "fries" to R.drawable.fries,
        "fruit_salad" to R.drawable.fruit_salad,
        "gumbo" to R.drawable.gumbo,
        "ice_cream" to R.drawable.ice_cream,
        "milk" to R.drawable.milk,
        "onion_rings" to R.drawable.onion_rings,
        "pancakes" to R.drawable.pancakes,
        "pie" to R.drawable.pie,
        "salad" to R.drawable.salad,
        "sandwich" to R.drawable.sandwich,
        "soft_drink" to R.drawable.soft_drink,
        "tacos" to R.drawable.tacos,
        "veggies" to R.drawable.veggies
    )

    fun resourceFor(canonicalName: String): Int? = canonicalToResource[canonicalName]
}
