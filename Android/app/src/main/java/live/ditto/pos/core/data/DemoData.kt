package live.ditto.pos.core.data

import live.ditto.pos.R
import live.ditto.pos.pos.data.OrderItemUiModel
import live.ditto.pos.pos.data.SaleItemUiModel

val demoMenuData = listOf(
    SaleItemUiModel(
        imageResource = R.drawable.burger,
        label = "Burger",
        price = 8.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.burrito,
        label = "Burrito",
        price = 6.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.chicken,
        label = "Fried Chicken",
        price = 8f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.chips,
        label = "Potato Chips",
        price = 2.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.coffee,
        label = "Coffee",
        price = 1.95f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.cookies,
        label = "Cookies",
        price = 3.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.corn_on_cob,
        label = "Corn",
        price = 3.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.fries,
        label = "French Fries",
        price = 3.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.fruit_salad,
        label = "Fruit Salad",
        price = 6.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.gumbo,
        label = "Gumbo",
        price = 9.95f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.ice_cream,
        label = "Ice Cream",
        price = 2.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.milk,
        label = "Milk",
        price = 2.0f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.onion_rings,
        label = "Onion Rings",
        price = 3.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.pancakes,
        label = "Pancakes",
        price = 5.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.pie,
        label = "Pie",
        price = 4.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.salad,
        label = "Salad",
        price = 6.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.sandwich,
        label = "Sandwich",
        price = 4.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.soft_drink,
        label = "Soft Drink",
        price = 1.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.tacos,
        label = "Tacos",
        price = 6.5f
    ),
    SaleItemUiModel(
        imageResource = R.drawable.veggies,
        label = "Veggie Plate",
        price = 7.5f
    )
)

val demoOrderItems = listOf(
    OrderItemUiModel(
        name = "Fries",
        price = "$3.99"
    ),
    OrderItemUiModel(
        name = "Burger",
        price = "$4.20"
    ),
    OrderItemUiModel(
        name = "Milkshake",
        price = "$1.50"
    ),
    OrderItemUiModel(
        name = "Hot Dog",
        price = "$9.00"
    )
)
