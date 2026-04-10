package live.ditto.pos.core.data.orders.ditto

import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime

const val ORDERS_COLLECTION_NAME = "orders"

const val LOCATION_ID_ATTRIBUTE_KEY = "locationId"
const val TTL_ATTRIBUTE_KEY = "TTL"

/**
 * Local midnight (start of today), formatted as UTC ISO 8601.
 * Using a fixed daily boundary means every device at the same
 * location produces the same subscription query, which is
 * important for Ditto sync efficiency.
 */
fun ttlTimestamp(): String {
    val localTz = TimeZone.currentSystemDefault()
    val today = Clock.System.now().toLocalDateTime(localTz).date
    return today.atStartOfDayIn(localTz).toString()
}

const val ORDERS_SALE_ITEM_ID_PLACEHOLDER = "{saleItemIdKey}"
const val ORDERS_TRANSACTION_ID_PLACEHOLDER = "{transactionId}"

const val SUBSCRIPTION_QUERY = """
    SELECT * FROM $ORDERS_COLLECTION_NAME
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
        AND createdOn > :TTL
    """

const val GET_ORDERS_FOR_LOCATION_QUERY = """
    SELECT * FROM $ORDERS_COLLECTION_NAME
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
        AND createdOn > :TTL
"""

const val INSERT_NEW_ORDER_QUERY = """
    INSERT INTO $ORDERS_COLLECTION_NAME
    DOCUMENTS (:new)
    ON ID CONFLICT DO NOTHING
"""

const val ADD_ITEM_TO_ORDER_QUERY = """
    UPDATE $ORDERS_COLLECTION_NAME
    SET
        saleItemIds.`$ORDERS_SALE_ITEM_ID_PLACEHOLDER` = :saleItemIdValue,
        status = :status
    WHERE _id = :_id
"""

const val UPDATE_ORDER_STATUS_QUERY = """
    UPDATE $ORDERS_COLLECTION_NAME
    SET status = :status
    WHERE _id = :_id
"""

const val ADD_TRANSACTION_TO_ORDER_QUERY = """
    UPDATE $ORDERS_COLLECTION_NAME
    SET transactionIds.`$ORDERS_TRANSACTION_ID_PLACEHOLDER` = :status
    WHERE _id = :_id
"""

const val CLEAR_SALE_ITEMS_ORDER_QUERY = """
    UPDATE $ORDERS_COLLECTION_NAME
    UNSET saleItemIds
    WHERE _id = :_id
"""
