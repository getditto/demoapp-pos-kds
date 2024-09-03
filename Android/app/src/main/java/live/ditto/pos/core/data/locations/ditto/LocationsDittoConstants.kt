package live.ditto.pos.core.data.locations.ditto

const val LOCATIONS_COLLECTIONS_NAME = "locations"

const val LOCATIONS_SUBSCRIPTION_QUERY = """
    SELECT * FROM COLLECTION $LOCATIONS_COLLECTIONS_NAME (saleItemIds MAP)
"""

const val SELECT_ALL_LOCATIONS_QUERY = """
    SELECT * FROM COLLECTION $LOCATIONS_COLLECTIONS_NAME (saleItemIds MAP)
"""
