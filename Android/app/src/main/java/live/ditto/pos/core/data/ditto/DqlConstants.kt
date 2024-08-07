package live.ditto.pos.core.data.ditto

/**
 * Location collection name
 */
const val LOCATION_COLLECTION_NAME = "location"

/**
 * Orders collection nane
 */
const val ORDERS_COLLECTION_NAME = "orders"

/**
 * Transactions collection name
 */
const val TRANSACTIONS_COLLECTION_NAME = "transactions"

/**
 * Default Location sync query
 */
const val DEFAULT_LOCATION_SYNC_QUERY = """SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :locationId
"""
