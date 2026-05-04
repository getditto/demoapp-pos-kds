package live.ditto.pos.core.data.demo

// Demo-only data.

import live.ditto.pos.core.data.SaleItem

object SaleItemSeed {
    private data class Item(
        val id: String,
        val name: String,
        val imageName: String,
        val cents: Int
    )

    private val catalog: List<Item> = listOf(
        Item("00001", "Burger", "burger", 850),
        Item("00002", "Burrito", "burrito", 650),
        Item("00003", "Fried Chicken", "chicken", 800),
        Item("00004", "Potato Chips", "chips", 250),
        Item("00005", "Coffee", "coffee", 195),
        Item("00006", "Cookies", "cookies", 350),
        Item("00007", "Corn", "corn", 350),
        Item("00008", "French Fries", "fries", 350),
        Item("00009", "Fruit Salad", "fruit_salad", 650),
        Item("00010", "Gumbo", "gumbo", 995),
        Item("00011", "Ice Cream", "ice_cream", 250),
        Item("00012", "Milk", "milk", 200),
        Item("00013", "Onion Rings", "onion_rings", 350),
        Item("00014", "Pancakes", "pancakes", 550),
        Item("00015", "Pie", "pie", 450),
        Item("00016", "Salad", "salad", 650),
        Item("00017", "Sandwich", "sandwich", 450),
        Item("00018", "Soft Drink", "soft_drink", 150),
        Item("00019", "Tacos", "tacos", 650),
        Item("00020", "Veggie Plate", "veggies", 750)
    )

    private val menus: Map<String, List<String>> = mapOf(
        "00001" to listOf("00001", "00008", "00013", "00018", "00012", "00011", "00006"),
        "00002" to listOf("00016", "00009", "00020", "00017", "00018", "00005", "00012"),
        "00003" to listOf("00003", "00017", "00016", "00020", "00018", "00005", "00006"),
        "00004" to listOf("00017", "00016", "00020", "00009", "00018", "00005", "00015"),
        "00005" to listOf("00014", "00009", "00005", "00012", "00011", "00015", "00006"),
        "00006" to listOf("00010", "00017", "00007", "00018", "00012", "00015"),
        "00007" to listOf("00019", "00002", "00007", "00018", "00003", "00011")
    )

    fun saleItemsForAllLocations(): List<SaleItem> {
        val byId = catalog.associateBy { it.id }
        return LocationSeed.demoLocations.flatMap { location ->
            (menus[location.id] ?: emptyList()).mapNotNull { itemId ->
                byId[itemId]?.let { item ->
                    SaleItem.seed(
                        id = item.id,
                        locationId = location.id,
                        name = item.name,
                        imageName = item.imageName,
                        cents = item.cents
                    )
                }
            }
        }
    }
}
